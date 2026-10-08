local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Catalog = require(ReplicatedStorage.AutoChess.Catalog)
local Rules = require(ReplicatedStorage.AutoChess.Rules)
local Lobby = require(ReplicatedStorage.AutoChess.Lobby)
local Config = require(ReplicatedStorage.AutoChess.PlaceConfig)
local RunService=game:GetService('RunService')
local TeleportService=game:GetService('TeleportService')
local World = require(script.Parent.World)
World.build()
local folder = Instance.new('Folder')
folder.Name = 'AutoChessRemotes'
folder.Parent = ReplicatedStorage
local action = Instance.new('RemoteEvent')
action.Name = 'Action'
action.Parent = folder
local update = Instance.new('RemoteEvent')
update.Name = 'Update'
update.Parent = folder
local states, lastAction = {}, {}
local phase, round, remaining = 'Lobby', 0, 0
local activeMatch = false
local lobbyEpoch=0
local tryStart
local arrivalTimerStarted=false
local rng = Random.new()
local pools = {COMMON={}, UNCOMMON={}, RARE={}, EPIC={}, ULTRA={}}
for name, data in pairs(Catalog.units) do
    if pools[data.rarity] and data.stars == 1 and not data.additional and not data.regional
        and data.skill ~= 'DEFAULT' then table.insert(pools[data.rarity], name) end
end
for _, pool in pairs(pools) do table.sort(pool) end
local rarities = {'COMMON','UNCOMMON','RARE','EPIC','ULTRA'}
local function shop(state)
    local result = {}
    local odds = Catalog.odds[tostring(state.level)]
    for i = 1, 6 do
        local roll, sum, rarity = rng:NextNumber(), 0, 'COMMON'
        for index, chance in ipairs(odds) do
            sum += chance
            if roll <= sum then rarity = rarities[index]; break end
        end
        local pool = pools[rarity]
        if #pool == 0 then pool = pools.COMMON end
        result[i] = pool[rng:NextInteger(1,#pool)]
    end
    return result
end
local function newState(player,slot)
    local state = {name=player.DisplayName, hp=100, gold=10, level=3, xp=0,
        units={}, offers={}, playing=false, battle=nil, opponent='',slot=slot,arena=slot,team=1}
    state.offers = shop(state)
    return state
end
local function queueCount()
    local count=0
    for _ in pairs(states) do count+=1 end
    return count
end
local function publish(player)
    local state = states[player]
    if not state or player.Parent ~= Players then return end
    local standings = {}
    for other, data in pairs(states) do
        table.insert(standings, {name=data.name, hp=data.hp, playing=data.playing,
            userId=other.UserId})
    end
    table.sort(standings,function(a,b) return a.hp > b.hp end)
    update:FireClient(player, {phase=phase, round=round, remaining=remaining,queueCount=queueCount(),requiredPlayers=Lobby.RequiredPlayers,
        state=state, standings=standings, synergies=Rules.synergies(state.units,Catalog)})
end
local function publishAll()
    World.LobbyLabel.Text=phase=='Lobby' and ('몬스터 아레나\n로비 · '..queueCount()..' / 8')
        or (phase=='Starting' and ('8명 집결!\n'..remaining..'초 후 출발') or '경기 진행 중')
    for player in pairs(states) do publish(player) end
end
local function returnToLobby(group)
    if RunService:IsStudio() then return end
    local ok,err=pcall(function() TeleportService:TeleportAsync(Config.LobbyPlaceId,group) end)
    if not ok then
        warn('Return teleport failed: '..tostring(err))
        for _,player in ipairs(group) do if states[player] then states[player].exitError='로비 이동 실패. 다시 이동 버튼을 눌러 주세요.' end end
        publishAll()
    end
end
TeleportService.TeleportInitFailed:Connect(function(player,_,errorMessage,placeId)
    if placeId==Config.LobbyPlaceId and states[player] then
        states[player].exitError='로비 이동 실패. 다시 이동 버튼을 눌러 주세요.'
        warn(tostring(errorMessage));publish(player)
    end
end)
local function participants()
    local list = {}
    for player, state in pairs(states) do
        if state.playing and state.hp > 0 then table.insert(list,player) end
    end
    table.sort(list,function(a,b) return a.UserId < b.UserId end)
    return list
end
local function countdown(seconds)
    for t=seconds,1,-1 do remaining=t; publishAll(); task.wait(1) end
    remaining=0
end
local function botBoard()
    local result = {}
    for i=1,math.min(6,2+math.floor(round/2)) do
        local unit=Rules.newUnit(pools.COMMON[rng:NextInteger(1,#pools.COMMON)])
        unit.x,unit.y=i,2
        table.insert(result,unit)
    end
    return result
end
local function runMatch()
    phase, round = 'Preparation', 0
    local initial = #participants()
    repeat
        round += 1
        phase='Preparation'
        for _,player in ipairs(participants()) do
            local state=states[player]
            state.battle=nil
            state.arena,state.team=state.slot,1
            World.route(player,state,phase)
            if round > 1 then state.gold += 5+math.min(5,math.floor(state.gold/10)) end
            state.offers=shop(state)
        end
        countdown(25)
        phase='Battle'
        local roster=participants()
        local battles={}
        for i=1,#roster,2 do
            local first,second=roster[i],roster[i+1]
            local enemy = second and states[second].units or botBoard()
            local simulation=Rules.battle(states[first].units,enemy,Catalog)
            table.insert(battles,{first=first,second=second,simulation=simulation})
            states[first].battle=simulation
            states[first].team=1
            states[first].arena=states[first].slot
            World.route(first,states[first],phase)
            states[first].opponent=second and states[second].name or '야생 포켓몬'
            if second then
                states[second].battle=simulation
                states[second].team=2
                states[second].arena=states[first].arena
                World.route(second,states[second],phase)
                states[second].opponent=states[first].name
            end
        end
        for tick=1,120 do
            local done=true
            for _,pair in ipairs(battles) do
                Rules.step(pair.simulation)
                if not pair.simulation.finished then done=false end
            end
            remaining=math.ceil((120-tick)*0.35)
            publishAll()
            if done then break end
            task.wait(0.35)
        end
        for _,pair in ipairs(battles) do
            for team,player in ipairs({pair.first,pair.second}) do
                local state=states[player]
                if state and pair.simulation.winner ~= team then
                    state.hp=math.max(0,state.hp-5-round)
                end
            end
        end
        phase='Results'
        countdown(5)
    until #participants() == 0 or (initial > 1 and #participants() <= 1) or round >= 10
    phase='Finished'
    publishAll()
    task.wait(8)
    if not RunService:IsStudio() then
        returnToLobby(Players:GetPlayers())
        return
    end
    phase='Lobby'
    activeMatch=false
    for player,state in pairs(states) do
        states[player]=newState(player,state.slot)
        World.route(player,states[player],phase)
    end
    publishAll()
    tryStart()
end
tryStart=function()
    if activeMatch or phase~='Lobby' or not Lobby.canStart(queueCount()) then return end
    activeMatch=true
    phase='Starting'
    lobbyEpoch+=1
    local epoch=lobbyEpoch
    task.spawn(function()
        for seconds=Lobby.CountdownSeconds,1,-1 do
            if lobbyEpoch~=epoch then return end
            if not Lobby.canStart(queueCount()) then
                phase,remaining,activeMatch='Lobby',0,false
                publishAll()
                return
            end
            remaining=seconds
            publishAll()
            task.wait(1)
        end
        if lobbyEpoch~=epoch or not Lobby.canStart(queueCount()) then return end
        for _,state in pairs(states) do state.playing=true end
        runMatch()
    end)
end
local function validInteger(value, low, high)
    return type(value)=='number' and value==value and value%1==0 and value>=low and value<=high
end
action.OnServerEvent:Connect(function(player, request)
    if type(request)~='table' or type(request.kind)~='string' then return end
    local state=states[player]
    if not state then return end
    local now=os.clock()
    if now-(lastAction[player] or 0)<0.1 then return end
    lastAction[player]=now
    if request.kind=='Sync' then publish(player); return end
    if request.kind=='Return' and phase=='Finished' then returnToLobby({player});return end
    if phase~='Preparation' or not state.playing or state.hp<=0 then return end
    if request.kind=='Buy' and validInteger(request.slot,1,6) then
        local name=state.offers[request.slot]
        if name and name~='' and Catalog.units[name] then
            local data=Catalog.units[name]
            local bench={}
            for _,unit in ipairs(state.units) do if unit.y==0 then bench[unit.x]=true end end
            local position
            for x=1,8 do if not bench[x] then position=x;break end end
            if position and state.gold>=data.cost then
                state.gold-=data.cost
                state.offers[request.slot]=''
                local unit=Rules.newUnit(name)
                unit.x=position
                table.insert(state.units,unit)
                Rules.merge(state,Catalog)
            end
        end
    elseif request.kind=='Move' and validInteger(request.id,1,1e12)
        and validInteger(request.x,1,8) and validInteger(request.y,0,3) then
        Rules.move(state,request.id,request.x,request.y)
    elseif request.kind=='Sell' and validInteger(request.id,1,1e12) then
        for index,unit in ipairs(state.units) do
            if unit.id==request.id then
                state.gold+=Catalog.units[unit.name].cost
                table.remove(state.units,index)
                break
            end
        end
    elseif request.kind=='Refresh' and state.gold>=2 then
        state.gold-=2
        state.offers=shop(state)
    elseif request.kind=='Experience' and state.gold>=4 and state.level<9 then
        state.gold-=4
        state.xp+=4
        local costs={0,2,6,10,22,34,52,72,72}
        while state.level<9 and state.xp>=costs[state.level+1] do
            state.xp-=costs[state.level+1]
            state.level+=1
        end
    end
    publish(player)
end)
local function joined(player)
    if not RunService:IsStudio() then
        local join=player:GetJoinData()
        if Config.LobbyPlaceId<=0 or Config.MatchPlaceId<=0 or game.PlaceId~=Config.MatchPlaceId
            or game.PrivateServerId=='' or game.PrivateServerOwnerId~=0
            or join.SourcePlaceId~=Config.LobbyPlaceId or join.SourceGameId~=game.GameId then
            player:Kick('로비의 경기 입장 구역을 통해 참가해 주세요.')
            return
        end
    end
    local slot=Lobby.slots(states)
    if not states[player] and not slot then
        player:Kick('이 서버는 최대 8명이 플레이할 수 있습니다.')
        return
    end
    if not states[player] then
        states[player]=newState(player,slot)
        player.CharacterAdded:Connect(function(character)
            character:WaitForChild('HumanoidRootPart',5)
            local state=states[player]
            if state and player.Character==character then World.route(player,state,phase) end
        end)
        World.route(player,states[player],phase)
    end
    publishAll()
    tryStart()
    if not RunService:IsStudio() and not arrivalTimerStarted then
        arrivalTimerStarted=true
        task.spawn(function()
            task.wait(60)
            if not activeMatch then
                phase='Finished'
                for _,state in pairs(states) do state.exitError='8명 도착 실패. 로비로 돌아갑니다.' end
                publishAll();returnToLobby(Players:GetPlayers())
            end
        end)
    end
end
Players.PlayerAdded:Connect(joined)
Players.PlayerRemoving:Connect(function(player)
    states[player],lastAction[player]=nil,nil
    if phase=='Starting' then
        lobbyEpoch+=1
        phase,remaining,activeMatch='Lobby',0,false
    end
    publishAll()
end)
for _,player in ipairs(Players:GetPlayers()) do joined(player) end
