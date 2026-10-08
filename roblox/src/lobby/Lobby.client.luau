local Players=game:GetService('Players')
local ReplicatedStorage=game:GetService('ReplicatedStorage')
local remotes=ReplicatedStorage:WaitForChild('LobbyRemotes')
local gui=Instance.new('ScreenGui');gui.Name='LobbyUI';gui.ResetOnSpawn=false
gui.Parent=Players.LocalPlayer:WaitForChild('PlayerGui')
local function label(text,y,height,button)
    local object=Instance.new(button and 'TextButton' or 'TextLabel')
    object.Size=UDim2.fromScale(0.55,height);object.Position=UDim2.fromScale(0.225,y)
    object.BackgroundColor3=Color3.fromRGB(20,35,53);object.BackgroundTransparency=0.15
    object.TextColor3=Color3.fromRGB(231,247,255);object.TextScaled=true
    object.Font=Enum.Font.GothamBold;object.Text=text;object.BorderSizePixel=0;object.Parent=gui
    local corner=Instance.new('UICorner');corner.CornerRadius=UDim.new(0,10);corner.Parent=object
    return object
end
label('MONSTER PLAZA',0.025,0.065)
label('광장 자유 탐험 · 스킨 상점 예정 · 빛나는 경기 입장 구역에서 대기',0.1,0.045)
local status=label('경기 대기 0 / 8',0.78,0.06)
local message=label('',0.845,0.045)
local leave=label('대기열 나가기',0.905,0.06,true);leave.Visible=false
leave.Activated:Connect(function() remotes.Leave:FireServer() end)
remotes.Update.OnClientEvent:Connect(function(payload)
    status.Text='경기 대기 '..payload.count..' / '..payload.required
    if payload.phase=='Countdown' then status.Text..=' · '..payload.remaining..'초 후 이동' end
    if payload.departing then status.Text='전용 경기 서버로 이동 중...' end
    message.Text=payload.message~='' and payload.message or (payload.inQueue and '대기 구역을 나가면 대기가 취소됩니다.' or '입장 구역에 들어온 사람만 경기에 참가합니다.')
    leave.Visible=payload.inQueue and not payload.departing
end)
