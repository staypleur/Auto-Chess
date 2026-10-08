local RunService=game:GetService('RunService')
local TweenService=game:GetService('TweenService')
local Debris=game:GetService('Debris')
local View={selected=nil,models={},key='',lastTick=-1}
local colors={FIRE=Color3.fromRGB(246,126,63),WATER=Color3.fromRGB(71,173,234),
    GRASS=Color3.fromRGB(98,190,117),ELECTRIC=Color3.fromRGB(250,213,75),
    POISON=Color3.fromRGB(182,107,223),ICE=Color3.fromRGB(133,233,242),
    ROCK=Color3.fromRGB(170,149,111),FAIRY=Color3.fromRGB(237,147,199),
    DRAGON=Color3.fromRGB(117,122,228),BUG=Color3.fromRGB(146,196,86)}
local function part(parent,name,size,offset,color,shape)
    local p=Instance.new('Part');p.Name=name;p.Size=size;p.CFrame=CFrame.new(offset)
    p.Color=color;p.Shape=shape or Enum.PartType.Ball;p.Anchored=true
    p.CanCollide=false;p.CanTouch=false;p.CastShadow=true;p.Parent=parent
    return p
end
local function creature(data,parent)
    local model=Instance.new('Model');model.Name=data.name;model.Parent=parent
    local color=colors[data.types[1]] or Color3.fromRGB(173,171,197)
    local seed=0;for i=1,#data.name do seed+=string.byte(data.name,i) end
    local scale=1+(data.stars-1)*0.18
    local torso=part(model,'Body',Vector3.new(3.8,3.1,4.4)*scale,Vector3.new(0,2.4,0),color)
    model.PrimaryPart=torso
    part(model,'Head',Vector3.new(3.1,2.9,2.9)*scale,Vector3.new(0,3.8,-2.1),color:Lerp(Color3.new(1,1,1),0.1))
    part(model,'Muzzle',Vector3.new(2,1.3,1.1),Vector3.new(0,3.2,-3.45),color:Lerp(Color3.new(1,1,1),0.4))
    for _,x in ipairs({-1.05,1.05}) do
        part(model,'Eye',Vector3.new(0.8,0.9,0.42),Vector3.new(x,4.05,-3.35),Color3.new(1,1,1))
        part(model,'Pupil',Vector3.new(0.38,0.53,0.2),Vector3.new(x,4.05,-3.57),Color3.fromRGB(24,35,49))
        local ear=part(model,'Ear',Vector3.new(0.9,1.5+(seed%3)*0.3,0.9),Vector3.new(x,5.2,-1.9),color)
        ear.Orientation=Vector3.new(0,0,x*20)
        for _,z in ipairs({-1.25,1.4}) do
            part(model,'Foot',Vector3.new(1.05,1.5,1.5),Vector3.new(x,0.9,z),color:Lerp(Color3.new(0,0,0),0.12))
        end
    end
    part(model,'Tail',Vector3.new(1,1,3),Vector3.new(0,2.3,3.1),color)
    local kinds={};for _,kind in ipairs(data.types) do kinds[kind]=true end
    if kinds.GRASS then
        part(model,'LeafCrown',Vector3.new(3.6,1.5,3.6),Vector3.new(0,4,0.8),Color3.fromRGB(58,151,80))
        part(model,'Bud',Vector3.new(1.8,2.4,1.8),Vector3.new(0,5.2,1),Color3.fromRGB(231,124,179))
    elseif kinds.FIRE then
        local flame=part(model,'TailFlame',Vector3.new(1.3,2.4,1.3),Vector3.new(0,3,4.4),Color3.fromRGB(255,199,75))
        flame.Material=Enum.Material.Neon
        local light=Instance.new('PointLight');light.Color=flame.Color;light.Range=9;light.Brightness=1;light.Parent=flame
    elseif kinds.WATER then
        part(model,'Shell',Vector3.new(3.6,2.4,3.6),Vector3.new(0,3.5,0.6),Color3.fromRGB(104,128,164))
    elseif kinds.ROCK or kinds.DRAGON then
        for z=0,2 do part(model,'Spine',Vector3.new(0.7,2,0.7),Vector3.new(0,4.3,z),color:Lerp(Color3.new(1,1,1),0.4)) end
    end
    if kinds.FLYING or kinds.BUG then
        for _,x in ipairs({-1,1}) do
            local wing=part(model,'Wing',Vector3.new(4,0.35,3),Vector3.new(x*3.2,3.6,0.4),color:Lerp(Color3.new(1,1,1),0.55))
            wing.Orientation=Vector3.new(0,0,x*20)
        end
    end
    local gui=Instance.new('BillboardGui');gui.Size=UDim2.fromOffset(150,46)
    gui.StudsOffset=Vector3.new(0,5,0);gui.AlwaysOnTop=true;gui.Adornee=torso;gui.Parent=model
    local title=Instance.new('TextLabel');title.Size=UDim2.fromScale(1,0.6)
    title.BackgroundTransparency=1;title.Text=data.name:gsub('_',' ')
    title.TextScaled=true;title.Font=Enum.Font.GothamBold;title.TextColor3=Color3.new(1,1,1)
    title.TextStrokeTransparency=0.4;title.Parent=gui
    local bg=Instance.new('Frame');bg.Position=UDim2.fromScale(0.1,0.7);bg.Size=UDim2.fromScale(0.8,0.16)
    bg.BackgroundColor3=Color3.fromRGB(37,46,60);bg.BorderSizePixel=0;bg.Parent=gui
    local hp=Instance.new('Frame');hp.Size=UDim2.fromScale(1,1);hp.BorderSizePixel=0;hp.Parent=bg
    local highlight=Instance.new('Highlight');highlight.Adornee=model;highlight.Enabled=false
    highlight.FillTransparency=0.65;highlight.OutlineColor=Color3.fromRGB(255,229,126);highlight.Parent=model
    return {model=model,hpBar=hp,highlight=highlight,position=Vector3.zero,target=Vector3.zero,
        direction=Vector3.new(0,0,-1),attackUntil=0,hitUntil=0,dead=false,seed=seed}
end
function View.clear()
    if View.folder then View.folder:Destroy() end
    View.folder=nil;View.models={};View.key='';View.lastTick=-1
end
function View.worldPosition(center,x,y)
    return center+Vector3.new((x-4.5)*8,0.6,(y-3.5)*8)
end
function View.render(payload,catalog)
    local state=payload.state
    if payload.phase=='Lobby' or payload.phase=='Starting' or not state.playing then
        View.clear()
        local camera=workspace.CurrentCamera
        camera.CameraType=Enum.CameraType.Custom
        camera.FieldOfView=70
        return
    end
    local center=Vector3.new(math.cos((state.arena-1)*math.pi/4)*235,0,math.sin((state.arena-1)*math.pi/4)*235)
    local mode=payload.phase=='Preparation' and 'Preparation' or 'Battle'
    local key=payload.round..':'..state.arena..':'..mode
    if View.key~=key then
        View.clear();View.key=key
        View.folder=Instance.new('Folder');View.folder.Name='LocalMonsterArena';View.folder.Parent=workspace
        if mode=='Preparation' then
            for y=1,3 do for x=1,8 do
                local pad=part(View.folder,'Placement',Vector3.new(7.4,0.12,7.4),View.worldPosition(center,x,y),Color3.fromRGB(93,231,205),Enum.PartType.Block)
                pad.Transparency=0.85;pad.Material=Enum.Material.Neon
                pad:SetAttribute('CellX',x);pad:SetAttribute('CellY',y)
            end end
        end
    end
    local camera=workspace.CurrentCamera;camera.CameraType=Enum.CameraType.Scriptable
    local sign=state.team==2 and 1 or -1
    camera.CFrame=CFrame.lookAt(center+Vector3.new(0,48,sign*54),center+Vector3.new(0,2,0))
    camera.Focus=CFrame.new(center)
    camera.FieldOfView=camera.ViewportSize.X/math.max(1,camera.ViewportSize.Y)<1.3 and 72 or 58
    local units=mode=='Preparation' and state.units or (state.battle and state.battle.fighters or {})
    local seen={}
    for _,unit in ipairs(units) do
        local id=tostring(unit.id);seen[id]=true
        local data=catalog.units[unit.name]
        local record=View.models[id]
        if not record then
            record=creature(data,View.folder);View.models[id]=record
            record.direction=Vector3.new(0,0,state.team==2 and -1 or 1)
        end
        record.target=View.worldPosition(center,unit.x,unit.y)
        if record.position==Vector3.zero then record.position=record.target end
        record.dead=unit.hp~=nil and unit.hp<=0
        record.model:SetAttribute('UnitId',unit.id)
        record.model:SetAttribute('CellX',unit.x);record.model:SetAttribute('CellY',unit.y)
        record.highlight.Enabled=mode=='Preparation' and unit.id==View.selected
        local own=mode=='Preparation' or unit.team==state.team
        record.hpBar.BackgroundColor3=own and Color3.fromRGB(103,239,159) or Color3.fromRGB(255,118,128)
        record.hpBar.Size=UDim2.fromScale(unit.hp and math.clamp(unit.hp/unit.maxHp,0,1) or 1,1)
        if record.dead then record.model:ScaleTo(0.3);record.hpBar.Parent.Parent.Enabled=false end
    end
    for id,record in pairs(View.models) do if not seen[id] then record.model:Destroy();View.models[id]=nil end end
    if state.battle and state.battle.tick~=View.lastTick then
        View.lastTick=state.battle.tick
        for _,event in ipairs(state.battle.events or {}) do
            local from,to=View.models[event.from],View.models[event.to]
            if from and to then
                from.attackUntil=os.clock()+0.24;to.hitUntil=os.clock()+0.2
                local delta=to.target-from.target
                if delta.Magnitude>0 then from.direction=delta.Unit end
                local spark=part(View.folder,'AttackOrb',Vector3.new(0.7,0.7,0.7),from.target+Vector3.new(0,3,0),from.hpBar.BackgroundColor3)
                spark.Material=Enum.Material.Neon
                TweenService:Create(spark,TweenInfo.new(0.18),{Position=to.target+Vector3.new(0,3,0)}):Play()
                Debris:AddItem(spark,0.2)
                local burst=part(View.folder,'Impact',Vector3.new(0.5,0.5,0.5),to.target+Vector3.new(0,2,0),Color3.fromRGB(255,236,148))
                burst.Material=Enum.Material.Neon
                TweenService:Create(burst,TweenInfo.new(0.22),{Size=Vector3.new(3,3,3),Transparency=1}):Play()
                Debris:AddItem(burst,0.65)
                local damageGui=Instance.new('BillboardGui');damageGui.Size=UDim2.fromOffset(90,50)
                damageGui.StudsOffset=Vector3.new(0,5,0);damageGui.AlwaysOnTop=true;damageGui.Parent=burst
                local damage=Instance.new('TextLabel');damage.Size=UDim2.fromScale(1,1)
                damage.BackgroundTransparency=1;damage.Text='-'..event.damage;damage.TextScaled=true
                damage.Font=Enum.Font.GothamBold;damage.TextColor3=Color3.fromRGB(255,218,97);damage.Parent=damageGui
            end
        end
    end
end
RunService.RenderStepped:Connect(function(dt)
    for _,record in pairs(View.models) do
        local delta=record.target-record.position
        if delta.Magnitude>0.08 then record.direction=delta.Unit end
        record.position=record.position:Lerp(record.target,1-math.exp(-12*dt))
        local now=os.clock()
        local bob=record.dead and 0 or math.sin(now*4+record.seed)*0.14
        local lunge=now<record.attackUntil and record.direction*0.9 or Vector3.zero
        local position=record.position+Vector3.new(0,2.4+bob,0)+lunge
        record.model:PivotTo(CFrame.lookAt(position,position+record.direction))
        if now<record.hitUntil then
            record.highlight.Enabled=true;record.highlight.FillColor=Color3.fromRGB(255,219,125)
        elseif View.key:find('Battle') then record.highlight.Enabled=false end
    end
end)
function View.preview(viewport,data)
    local world=Instance.new('WorldModel');world.Parent=viewport
    local record=creature(data,world)
    local gui=record.model:FindFirstChildOfClass('BillboardGui');if gui then gui:Destroy() end
    local camera=Instance.new('Camera');camera.CFrame=CFrame.lookAt(Vector3.new(7,6,-11),Vector3.new(0,2,0))
    camera.FieldOfView=40;camera.Parent=viewport;viewport.CurrentCamera=camera
    viewport.Ambient=Color3.fromRGB(180,190,210)
    viewport.LightColor=Color3.fromRGB(255,231,209)
end
return View
