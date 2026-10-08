-- Pure queue rules. No solo-start override, including in Studio.
local Lobby = {RequiredPlayers = 8, CountdownSeconds = 8}
function Lobby.canStart(count) return count == Lobby.RequiredPlayers end
function Lobby.slots(states)
    local used={}
    for _,state in pairs(states) do used[state.slot]=true end
    for slot=1,Lobby.RequiredPlayers do if not used[slot] then return slot end end
    return nil
end
return Lobby
