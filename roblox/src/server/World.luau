local World={Centers={}}
local Lighting=game:GetService('Lighting')
local function part(parent,name,size,position,color,material)
    local p=Instance.new('Part')
    p.Name=name;p.Size=size;p.Position=position;p.Anchored=true
    p.Material=material or Enum.Material.SmoothPlastic;p.Color=color
    p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth
    p.Parent=parent
    return p
end
local function text(partObject,message)
    local gui=Instance.new('BillboardGui')
    gui.Size=UDim2.fromOffset(450,100);gui.StudsOffset=Vector3.new(0,5,0)
    gui.AlwaysOnTop=true;gui.Parent=partObject
    local label=Instance.new('TextLabel')
    label.Size=UDim2.fromScale(1,1);label.BackgroundTransparency=1
    label.Text=message;label.TextColor3=Color3.fromRGB(230,250,255)
    label.TextScaled=true;label.Font=Enum.Font.GothamBold;label.Parent=gui
    return label
end
local function tree(parent,position)
    part(parent,'Trunk',Vector3.new(2,10,2),position+Vector3.new(0,5,0),Color3.fromRGB(102,69,49))
    local crown=part(parent,'Canopy',Vector3.new(11,12,11),position+Vector3.new(0,13,0),Color3.fromRGB(40,115,88))
    crown.Shape=Enum.PartType.Ball
end
function World.build()
    local old=workspace:FindFirstChild('AutoChessWorld');if old then old:Destroy() end
    local root=Instance.new('Folder');root.Name='AutoChessWorld';root.Parent=workspace
    Lighting.ClockTime=17.3;Lighting.Brightness=2
    Lighting.Ambient=Color3.fromRGB(105,120,150)
    local atmosphere=Instance.new('Atmosphere');atmosphere.Density=0.24
    atmosphere.Color=Color3.fromRGB(175,209,235);atmosphere.Parent=Lighting
    local bloom=Instance.new('BloomEffect');bloom.Intensity=0.35;bloom.Size=30;bloom.Parent=Lighting
    local lobby=Instance.new('Folder');lobby.Name='Lobby';lobby.Parent=root
    part(lobby,'Island',Vector3.new(120,12,120),Vector3.new(0,-7,0),Color3.fromRGB(55,65,88),Enum.Material.Slate)
    part(lobby,'Garden',Vector3.new(116,1,116),Vector3.new(0,-0.5,0),Color3.fromRGB(57,94,88),Enum.Material.Grass)
    part(lobby,'Plaza',Vector3.new(52,0.5,52),Vector3.new(0,0.25,0),Color3.fromRGB(56,65,94),Enum.Material.Marble)
    local fountain=part(lobby,'Portal',Vector3.new(1,15,15),Vector3.new(0,0.8,0),Color3.fromRGB(57,222,224),Enum.Material.Neon)
    fountain.Shape=Enum.PartType.Cylinder;fountain.Orientation=Vector3.new(0,0,90)
    World.LobbyLabel=text(fountain,'몬스터 아레나\n로비 · 0 / 8')
    for i=1,8 do
        local angle=(i-1)*math.pi/4
        local pos=Vector3.new(math.cos(angle)*36,0,math.sin(angle)*36)
        local pad=part(lobby,'PlayerPad'..i,Vector3.new(7,0.4,7),pos+Vector3.new(0,0.6,0),Color3.fromRGB(50,187,197),Enum.Material.Neon)
        text(pad,tostring(i))
        tree(lobby,Vector3.new(math.cos(angle)*51,0,math.sin(angle)*51))
        local center=Vector3.new(math.cos(angle)*235,0,math.sin(angle)*235)
        World.Centers[i]=center
        local arena=Instance.new('Folder');arena.Name='Arena'..i;arena.Parent=root
        part(arena,'FloatingRock',Vector3.new(100,14,88),center+Vector3.new(0,-8,0),Color3.fromRGB(62,70,93),Enum.Material.Slate)
        part(arena,'ArenaGrass',Vector3.new(96,1,84),center+Vector3.new(0,-0.5,0),Color3.fromRGB(45,87,76),Enum.Material.Grass)
        part(arena,'BattleField',Vector3.new(66,0.5,50),center+Vector3.new(0,0.25,0),Color3.fromRGB(82,113,110),Enum.Material.Slate)
        for _,z in ipairs({-28,28}) do
            part(arena,'Rim',Vector3.new(72,0.6,0.4),center+Vector3.new(0,0.6,z),Color3.fromRGB(74,209,223),Enum.Material.Neon)
        end
        for _,x in ipairs({-38,38}) do
            for _,z in ipairs({-31,31}) do
                tree(arena,center+Vector3.new(x,0,z))
                local crystal=part(arena,'Crystal',Vector3.new(3,7,3),center+Vector3.new(x,4,z+5),Color3.fromRGB(112,169,247),Enum.Material.Neon)
                crystal.Orientation=Vector3.new(0,45,20)
            end
        end
        local stand=part(arena,'SpectatorTerrace',Vector3.new(70,2,10),center+Vector3.new(0,2,37),Color3.fromRGB(68,77,106),Enum.Material.Marble)
        text(stand,'ARENA '..i)
    end
    local spawn=workspace:FindFirstChild('Spawn')
    if spawn then spawn.Position=Vector3.new(0,2,20) end
end
function World.position(arena,x,y)
    return World.Centers[arena]+Vector3.new((x-4.5)*8,0.6,(y-3.5)*8)
end
function World.route(player,state,phase)
    local character=player.Character
    if not character then return end
    local position
    if phase=='Lobby' or phase=='Starting' or not state.playing then
        local angle=(state.slot-1)*math.pi/4
        position=Vector3.new(math.cos(angle)*36,4,math.sin(angle)*36)
    else
        position=World.Centers[state.arena or state.slot]+Vector3.new(0,5,state.team==2 and 36 or -36)
    end
    character:PivotTo(CFrame.new(position))
    local humanoid=character:FindFirstChildOfClass('Humanoid')
    if humanoid then
        local lobby=phase=='Lobby' or phase=='Starting' or not state.playing
        humanoid.WalkSpeed=lobby and 16 or 0
        humanoid.JumpPower=lobby and 50 or 0
        humanoid.JumpHeight=lobby and 7.2 or 0
    end
end
return World
