local Lobby=require('../src/shared/Lobby')
for count=0,7 do assert(not Lobby.canStart(count),'must not start with '..count) end
assert(Lobby.canStart(8),'eight players must start')
assert(not Lobby.canStart(9),'oversized queue must not start')
local states={}
for i=1,8 do
    assert(Lobby.slots(states)==i,'next slot assignment')
    states[i]={slot=i}
end
assert(Lobby.slots(states)==nil,'full lobby rejects extra slots')
states[3]=nil
assert(not Lobby.canStart(7),'disconnect cancels eligibility')
assert(Lobby.slots(states)==3,'vacant slot reused')
assert(Lobby.CountdownSeconds==8,'start countdown')
print('ALL LOBBY TESTS PASSED')
