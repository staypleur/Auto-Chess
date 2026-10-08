local Players=game:GetService('Players')
local ReplicatedStorage=game:GetService('ReplicatedStorage')
local TeleportService=game:GetService('TeleportService')
local RunService=game:GetService('RunService')
local Config=require(ReplicatedStorage.AutoChess.PlaceConfig)
local Queue=require(ReplicatedStorage.AutoChess.Queue)
local World=require(script.Parent.World)
World.build(true)
local sign=World.queueZone()
local folder=Instance.new('Folder');folder.Name='LobbyRemotes';folder.Parent=ReplicatedStorage
local update=Instance.new('RemoteEvent');update.Name='Update';update.Parent=folder
local leave=Instance.new('RemoteEvent');leave.Name='Leave';leave.Parent=folder
local queue,departing,retries={},{},{}
local phase,remaining,message='Waiting',0,''
local countdownStart=nil
local busy=false
local lastLeave={}
local function publish()
    sign.Text='경기 입장\n'..#queue..' / '..Config.RequiredPlayers..(remaining>0 and (' · '..remaining..'초') or '')
    for _,player in ipairs(Players:GetPlayers()) do
        local inQueue=table.find(queue,player)~=nil
        update:FireClient(player,{count=#queue,required=Config.RequiredPlayers,phase=phase,
            remaining=remaining,inQueue=inQueue,departing=departing[player]~=nil,message=message})
    end
end
local function resetQueue(text)
    phase,remaining,message='Waiting',0,text or ''
    countdownStart=nil
    busy=false
end
local function sendBatch(batch)
    busy=true;phase='Teleporting';remaining=0
    if RunService:IsStudio() then
        resetQueue('Studio에서는 서버 이동이 불가합니다. 8명 대기열 확인 완료!')
        countdownStart=nil
        phase='StudioReady'
        publish()
        return
    end
    if Config.MatchPlaceId<=0 or Config.LobbyPlaceId<=0 or Config.MatchPlaceId==Config.LobbyPlaceId or game.PlaceId~=Config.LobbyPlaceId then
        resetQueue('PlaceConfig에 서로 다른 로비/경기장 Place ID를 입력해 주세요.')
        phase='ConfigurationError';publish();return
    end
    local options
    local ok,err=pcall(function()
        local code=TeleportService:ReserveServerAsync(Config.MatchPlaceId)
        options=Instance.new('TeleportOptions');options.ReservedServerAccessCode=code
        options:SetTeleportData({kind='AutoChessMatch',lobbyPlaceId=Config.LobbyPlaceId})
        for _,player in ipairs(batch) do departing[player]={options=options,deadline=os.clock()+45};retries[player]=0 end
        publish()
        TeleportService:TeleportAsync(Config.MatchPlaceId,batch,options)
    end)
    if not ok then
        warn('Match teleport failed: '..tostring(err))
        for _,player in ipairs(batch) do departing[player]=nil end
        resetQueue('이동 요청 실패. 대기 구역을 나갔다가 다시 들어와 주세요.')
        phase='TeleportError'
    else
        queue={};resetQueue('새 경기 대기 중')
    end
    publish()
end
TeleportService.TeleportInitFailed:Connect(function(player,_,errorMessage,placeId,options)
    local transfer=departing[player]
    if not transfer or placeId~=Config.MatchPlaceId then return end
    retries[player]=(retries[player] or 0)+1
    if retries[player]<=3 and player.Parent==Players then
        task.spawn(function()
            task.wait(2)
            if player.Parent~=Players or not departing[player] then return end
            local ok=pcall(function() TeleportService:TeleportAsync(placeId,{player},options) end)
            if not ok then departing[player]=nil;message='일부 참가자 이동 실패. 대기 구역에서 다시 시도해 주세요.' end
        end)
    else
        departing[player]=nil
        message='이동 실패: 다시 대기 구역에 입장해 주세요.'
        warn('TeleportInitFailed: '..tostring(errorMessage))
    end
end)
leave.OnServerEvent:Connect(function(player)
    local now=os.clock();if now-(lastLeave[player] or -1)<1 then return end
    lastLeave[player]=now
    if departing[player] then return end
    if player.Character and table.find(queue,player) then player.Character:PivotTo(CFrame.new(0,4,-20)) end
end)
Players.PlayerRemoving:Connect(function(player)
    departing[player],retries[player],lastLeave[player]=nil,nil,nil
end)
task.spawn(function()
    while true do
        local inside={}
        for _,player in ipairs(Players:GetPlayers()) do
            local transfer=departing[player]
            if transfer and os.clock()>transfer.deadline then
                departing[player]=nil;message='이동 제한 시간 초과. 다시 대기해 주세요.'
            end
            local root=player.Character and player.Character:FindFirstChild('HumanoidRootPart')
            if root and not departing[player] and Queue.inside(root.Position.X,root.Position.Y,root.Position.Z) then
                table.insert(inside,player)
            end
        end
        if not busy then
            local nextQueue=Queue.reconcile(queue,inside)
            if not Queue.same(queue,nextQueue) then
                queue=nextQueue;countdownStart=nil;phase='Waiting';message=''
            end
            if #queue==Config.RequiredPlayers and phase~='StudioReady' and phase~='ConfigurationError' and phase~='TeleportError' then
                countdownStart=countdownStart or os.clock()
                phase='Countdown';remaining=math.max(0,Config.CountdownSeconds-math.floor(os.clock()-countdownStart))
                if remaining==0 then
                    local batch=table.clone(queue)
                    task.spawn(function() sendBatch(batch) end)
                end
            else remaining=0 end
        end
        publish();task.wait(0.25)
    end
end)
