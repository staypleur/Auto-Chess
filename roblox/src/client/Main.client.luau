local Players=game:GetService('Players')
local ReplicatedStorage=game:GetService('ReplicatedStorage')
local UserInputService=game:GetService('UserInputService')
local GuiService=game:GetService('GuiService')
local Catalog=require(ReplicatedStorage:WaitForChild('AutoChess'):WaitForChild('Catalog'))
local View=require(script.Parent.ArenaView)
local remotes=ReplicatedStorage:WaitForChild('AutoChessRemotes')
local action=remotes:WaitForChild('Action')
local update=remotes:WaitForChild('Update')
local player=Players.LocalPlayer
local gui=Instance.new('ScreenGui');gui.Name='AutoChessUI';gui.ResetOnSpawn=false
gui.Parent=player:WaitForChild('PlayerGui')
local root=Instance.new('Frame');root.Size=UDim2.fromScale(1,1)
root.BackgroundTransparency=1;root.Parent=gui
local selected,latest=nil,nil
local function send(kind,values)
    values=values or {};values.kind=kind;action:FireServer(values)
end
local function label(parent,text,x,y,w,h,button)
    local object=Instance.new(button and 'TextButton' or 'TextLabel')
    object.Position=UDim2.fromScale(x,y);object.Size=UDim2.fromScale(w,h)
    object.Text=text;object.TextScaled=true;object.Font=Enum.Font.GothamBold
    object.TextColor3=Color3.fromRGB(235,245,255)
    object.BackgroundColor3=Color3.fromRGB(19,33,49);object.BackgroundTransparency=0.12
    object.BorderSizePixel=0;object.Parent=parent
    local corner=Instance.new('UICorner');corner.CornerRadius=UDim.new(0,9);corner.Parent=object
    local pad=Instance.new('UIPadding');pad.PaddingLeft=UDim.new(0,6);pad.PaddingRight=UDim.new(0,6);pad.Parent=object
    return object
end
local phaseNames={Lobby='로비',Starting='경기장 이동 대기',Preparation='전투 준비',Battle='자동 전투',Results='라운드 결과',Finished='경기 종료'}
local function draw(payload)
    latest=payload
    root:ClearAllChildren()
    local state=payload.state
    local known=false;for _,unit in ipairs(state.units) do if unit.id==selected then known=true end end
    if not known then selected=nil end
    View.selected=selected;View.render(payload,Catalog)
    local waiting=payload.phase=='Lobby' or payload.phase=='Starting'
    if waiting then
        label(root,'MONSTER ARENA',0.25,0.05,0.5,0.07)
        label(root,'8명이 모이면 자동으로 시작합니다',0.25,0.13,0.5,0.05)
        local count=label(root,payload.queueCount..' / '..payload.requiredPlayers,0.4,0.2,0.2,0.08)
        count.TextColor3=Color3.fromRGB(113,236,219)
        if payload.phase=='Starting' then
            label(root,payload.remaining..'초 후 경기장으로 이동',0.3,0.3,0.4,0.05)
        else label(root,'광장을 둘러보며 친구들을 기다려 주세요',0.25,0.9,0.5,0.05) end
    else
        label(root,string.format('%s · ROUND %d · %ds',phaseNames[payload.phase],payload.round,payload.remaining),0.02,0.02,0.6,0.055)
        label(root,string.format('HP %d  |  %d GOLD  |  Lv.%d  ·  %d XP',state.hp,state.gold,state.level,state.xp),0.02,0.085,0.6,0.04)
        if payload.phase=='Preparation' and state.hp>0 and state.playing then
            label(root,'몬스터 선택 → 경기장 위치 클릭 · 빈칸은 배치 가능 위치입니다',0.02,0.135,0.6,0.035)
            for x=1,8 do
                local unit
                for _,candidate in ipairs(state.units) do if candidate.y==0 and candidate.x==x then unit=candidate end end
                local text=unit and unit.name:gsub('_',' ') or '벤치 '..x
                if unit and selected==unit.id then text='▶ '..text end
                local bench=label(root,text,0.02+(x-1)*0.095,0.66,0.09,0.045,true)
                bench.Activated:Connect(function()
                    if selected then send('Move',{id=selected,x=x,y=0});selected=nil
                    elseif unit then selected=unit.id;draw(latest) end
                end)
            end
            for slot=1,6 do
                local data=Catalog.units[state.offers[slot]]
                local card=label(root,'',0.02+(slot-1)*0.127,0.72,0.12,0.16,true)
                if data then
                    local portrait=Instance.new('ViewportFrame');portrait.Size=UDim2.fromScale(1,0.68)
                    portrait.BackgroundTransparency=1;portrait.Active=false;portrait.Parent=card
                    View.preview(portrait,data)
                    local title=label(card,data.name:gsub('_',' ')..' · '..data.cost..'G',0,0.7,1,0.28)
                    title.BackgroundTransparency=1
                else card.Text='판매 완료' end
                card.Activated:Connect(function() send('Buy',{slot=slot}) end)
            end
            for i,buttonData in ipairs({{'새로고침 · 2G','Refresh'},{'경험치 +4 · 4G','Experience'},{'선택 몬스터 판매','Sell'}}) do
                local button=label(root,buttonData[1],0.02+(i-1)*0.255,0.9,0.245,0.06,true)
                button.Activated:Connect(function()
                    if buttonData[2]=='Sell' then
                        if selected then send('Sell',{id=selected});selected=nil end
                    else send(buttonData[2]) end
                end)
            end
        elseif state.battle then
            local text='VS '..state.opponent
            if payload.phase=='Results' then
                text=state.battle.winner==0 and '무승부' or (state.battle.winner==state.team and '승리!' or '패배')
            elseif payload.phase=='Finished' then text='경기 종료 · 잠시 후 로비로 돌아갑니다' end
            label(root,text,0.23,0.87,0.5,0.07)
        else label(root,'다음 경기를 기다리는 중',0.3,0.88,0.4,0.06) end
    end
    label(root,'PLAYERS',0.81,0.02,0.17,0.045)
    for i,standing in ipairs(payload.standings) do
        label(root,standing.name..(waiting and '' or (' · '..standing.hp..' HP')),0.81,0.075+(i-1)*0.045,0.17,0.04)
    end
    if not waiting then
        local types={};for kind,count in pairs(payload.synergies) do table.insert(types,kind..' '..count) end
        table.sort(types);label(root,'타입 수집\n'..table.concat(types,'\n'),0.81,0.53,0.17,0.24)
    end
    if payload.phase=='Finished' then
        local button=label(root,state.exitError or '로비로 돌아가기',0.25,0.77,0.5,0.06,true)
        button.Activated:Connect(function() send('Return') end)
    end
end
local function worldClick(position)
    if not latest or latest.phase~='Preparation' or not View.folder then return end
    local inset=GuiService:GetGuiInset()
    local ray=workspace.CurrentCamera:ScreenPointToRay(position.X-inset.X,position.Y-inset.Y)
    local parameters=RaycastParams.new();parameters.FilterType=Enum.RaycastFilterType.Include
    parameters.FilterDescendantsInstances={View.folder}
    local hit=workspace:Raycast(ray.Origin,ray.Direction*1000,parameters)
    if not hit then return end
    local object=hit.Instance
    while object and object~=View.folder and object:GetAttribute('CellX')==nil do object=object.Parent end
    if not object or object==View.folder then return end
    local x,y=object:GetAttribute('CellX'),object:GetAttribute('CellY')
    local id=object:GetAttribute('UnitId')
    if selected and x and y then send('Move',{id=selected,x=x,y=y});selected=nil
    elseif id then selected=id end
    draw(latest)
end
UserInputService.InputBegan:Connect(function(input,processed)
    if processed then return end
    if input.UserInputType==Enum.UserInputType.MouseButton1 then worldClick(UserInputService:GetMouseLocation()) end
    if input.KeyCode==Enum.KeyCode.Escape then selected=nil;if latest then draw(latest) end end
end)
UserInputService.TouchTapInWorld:Connect(function(position,processed) if not processed then worldClick(position) end end)
update.OnClientEvent:Connect(draw)
send('Sync')
