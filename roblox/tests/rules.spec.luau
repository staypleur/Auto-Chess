local Rules=require('../src/shared/Rules')
local Catalog=require('../src/shared/Catalog')
local function check(ok,message) assert(ok,message);print('PASS '..message) end
local count=0
for _,unit in pairs(Catalog.units) do
    count+=1
    check(type(unit.attack)=='number' and type(unit.speed)=='number','stats '..unit.name)
end
assert(count==1183,'catalog count')
local state={level=1,units={}}
local a=Rules.newUnit('BULBASAUR')
a.x=1
table.insert(state.units,a)
check(Rules.move(state,a.id,1,1),'bench to board')
local b=Rules.newUnit('BULBASAUR')
b.x=2
table.insert(state.units,b)
check(not Rules.move(state,b.id,2,1),'deployment cap')
check(Rules.move(state,b.id,1,1) and a.y==0,'swap at capacity')
check(not Rules.move(state,b.id,1,4),'opponent half rejected')
check(not Rules.move(state,999,1,1),'foreign unit rejected')
local c=Rules.newUnit('BULBASAUR')
c.x=3
table.insert(state.units,c)
Rules.merge(state,Catalog)
check(#state.units==1 and state.units[1].name=='IVYSAUR','count evolution uses upstream rule')
local deployed=state.units[1]
deployed.y=1
local battle=Rules.battle({deployed},{},Catalog)
Rules.step(battle)
check(battle.finished and battle.winner==1,'empty opponent loses')
local enemy=Rules.newUnit('BULBASAUR')
enemy.x,enemy.y=1,1
battle=Rules.battle({deployed},{enemy},Catalog)
for _=1,120 do Rules.step(battle) end
check(battle.finished,'combat terminates')
check(deployed.name=='IVYSAUR' and deployed.y==1,'combat does not mutate collection')
local duplicate=Rules.newUnit('IVYSAUR')
duplicate.x,duplicate.y=2,1
local synergies=Rules.synergies({deployed,duplicate},Catalog)
check(synergies.GRASS==1,'duplicate families count once')
print('ALL RULE TESTS PASSED')
