local Players=game:GetService('Players')
local ReplicatedStorage=game:GetService('ReplicatedStorage')
local Catalog=require(ReplicatedStorage:WaitForChild('AutoChess'):WaitForChild('Catalog'))
local remotes=ReplicatedStorage:WaitForChild('AutoChessRemotes')
local action=remotes:WaitForChild('Action')
local update=remotes:WaitForChild('Update')
local player=Players.LocalPlayer
local gui=Instance.new('ScreenGui')
gui.Name='AutoChessUI'
gui.ResetOnSpawn=false
gui.IgnoreGuiInset=false
gui.Parent=player:WaitForChild('PlayerGui')
local root=Instance.new('Frame')
root.Size=UDim2.fromScale(1,1)
root.BackgroundColor3=Color3.fromRGB(15,22,36)
root.Parent=gui
local selected=nil
local latest=nil
local function send(kind,values)
    values=values or {}
    values.kind=kind
    action:FireServer(values)
end
local function label(parent,text,x,y,w,h,button)
    local object=Instance.new(button and 'TextButton' or 'TextLabel')
    object.Position=UDim2.fromScale(x,y)
    object.Size=UDim2.fromScale(w,h)
    object.Text=text
    object.TextScaled=true
    object.Font=Enum.Font.Gotham
    object.TextColor3=Color3.fromRGB(235,242,255)
    object.BackgroundColor3=Color3.fromRGB(34,49,72)
    object.BorderSizePixel=0
    object.Parent=parent
    local padding=Instance.new('UIPadding')
    padding.PaddingLeft=UDim.new(0,4)
    padding.PaddingRight=UDim.new(0,4)
    padding.Parent=object
    local corner=Instance.new('UICorner')
    corner.CornerRadius=UDim.new(0,5)
    corner.Parent=object
    return object
end
local phaseNames={Lobby='로비',Starting='시작 대기',Preparation='준비',Battle='전투',Results='결과',Finished='경기 종료'}
local function draw(payload)
    latest=payload
    root:ClearAllChildren()
    local state=payload.state
    local known=false
    for _,unit in ipairs(state.units) do if unit.id==selected then known=true end end
    if not known then selected=nil end
    label(root,'POKÉMON AUTO CHESS · ROBLOX PORT',0.02,0.01,0.76,0.045)
    label(root,string.format('%s · R%d · %ds | HP %d · 골드 %d · Lv%d (%d XP)',
        phaseNames[payload.phase] or payload.phase,payload.round,payload.remaining,
        state.hp,state.gold,state.level,state.xp),0.02,0.065,0.76,0.045)
    label(root,'유닛 선택 → 아래쪽 보드/벤치 클릭으로 배치 · 전투 중에는 수정 불가',0.02,0.12,0.76,0.035)
    local pieces={}
    if payload.phase=='Battle' or payload.phase=='Results' then
        if state.battle then
            for _,fighter in ipairs(state.battle.fighters) do
                local y=state.team==2 and 7-fighter.y or fighter.y
                if fighter.hp>0 then pieces[fighter.x..':'..y]=fighter end
            end
        end
    else
        for _,unit in ipairs(state.units) do
            if unit.y>0 then pieces[unit.x..':'..unit.y]=unit end
        end
    end
    for y=6,1,-1 do
        for x=1,8 do
            local piece=pieces[x..':'..y]
            local text=piece and piece.name:gsub('_',' ') or ''
            if piece and piece.hp then text..='\n'..piece.hp..'/'..piece.maxHp end
            if piece and piece.id==selected then text='▶ '..text end
            local cell=label(root,text,0.02+(x-1)*0.095,0.17+(6-y)*0.072,0.09,0.065,true)
            cell.BackgroundColor3=y>3 and Color3.fromRGB(66,35,49) or Color3.fromRGB(26,66,69)
            cell.Activated:Connect(function()
                if payload.phase~='Preparation' then return end
                if selected and y<=3 then send('Move',{id=selected,x=x,y=y});selected=nil
                elseif piece then selected=piece.id;draw(latest) end
            end)
        end
    end
    for x=1,8 do
        local unit
        for _,item in ipairs(state.units) do if item.y==0 and item.x==x then unit=item end end
        local text=unit and unit.name:gsub('_',' ') or '벤치 '..x
        if unit and unit.id==selected then text='▶ '..text end
        local cell=label(root,text,0.02+(x-1)*0.095,0.62,0.09,0.065,true)
        cell.Activated:Connect(function()
            if payload.phase~='Preparation' then return end
            if selected then send('Move',{id=selected,x=x,y=0});selected=nil
            elseif unit then selected=unit.id;draw(latest) end
        end)
    end
    for slot=1,6 do
        local name=state.offers[slot]
        local data=Catalog.units[name]
        local text=data and (name:gsub('_',' ')..'\n'..data.cost..'G · '..table.concat(data.types,'/')) or '판매 완료'
        local card=label(root,text,0.02+(slot-1)*0.127,0.72,0.12,0.11,true)
        card.Activated:Connect(function() send('Buy',{slot=slot}) end)
    end
    local buttons={{'시작 / 준비','Ready'},{'새로고침 2G','Refresh'},{'경험치 +4 / 4G','Experience'},{'선택 유닛 판매','Sell'}}
    for i,item in ipairs(buttons) do
        local button=label(root,item[1],0.02+(i-1)*0.19,0.86,0.18,0.06,true)
        button.Activated:Connect(function()
            if item[2]=='Sell' then if selected then send('Sell',{id=selected});selected=nil end
            else send(item[2]) end
        end)
    end
    label(root,'플레이어',0.81,0.02,0.17,0.05)
    for i,standing in ipairs(payload.standings) do
        label(root,standing.name..' · '..standing.hp..' HP',0.81,0.08+(i-1)*0.05,0.17,0.045)
    end
    local synergies={}
    for kind,count in pairs(payload.synergies) do table.insert(synergies,kind..' '..count) end
    table.sort(synergies)
    label(root,'타입 수집\n'..table.concat(synergies,'\n'),0.81,0.52,0.17,0.25)
    label(root,'초기 이식 버전\n스킬·아이템·시너지 효과 미구현\n그래픽: 임시 텍스트',0.81,0.8,0.17,0.14)
end
update.OnClientEvent:Connect(draw)
send('Sync')
