local Config=if script then require(script.Parent.PlaceConfig) else require('./PlaceConfig')
local Queue={}
function Queue.inside(x,y,z)
    local c,s=Config.ZoneCenter,Config.ZoneSize
    return math.abs(x-c.x)<=s.x/2 and math.abs(y-c.y)<=s.y/2 and math.abs(z-c.z)<=s.z/2
end
function Queue.reconcile(previous,inside)
    local present,added,result={},{},{}
    for _,member in ipairs(inside) do present[member]=true end
    for _,member in ipairs(previous) do
        if present[member] and not added[member] and #result<Config.RequiredPlayers then
            table.insert(result,member);added[member]=true
        end
    end
    for _,member in ipairs(inside) do
        if not added[member] and #result<Config.RequiredPlayers then
            table.insert(result,member);added[member]=true
        end
    end
    return result
end
function Queue.same(first,second)
    if #first~=#second then return false end
    for index,member in ipairs(first) do if second[index]~=member then return false end end
    return true
end
return Queue
