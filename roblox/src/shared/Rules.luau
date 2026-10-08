-- GPL-3.0-only. Pure game rules; no Roblox services required.
local Rules = {}
Rules.Width = 8
Rules.Height = 6
Rules.BenchSize = 8
Rules.ShopSize = 6
local nextId = 0

function Rules.newUnit(name)
    nextId += 1
    return { id = nextId, name = name, x = 0, y = 0 }
end

function Rules.deployed(state)
    local count = 0
    for _, unit in ipairs(state.units) do
        if unit.y > 0 then count += 1 end
    end
    return count
end

function Rules.merge(state, catalog)
    local changed = true
    while changed do
        changed = false
        for _, candidate in ipairs(state.units) do
            local data = catalog.units[candidate.name]
            if data.evolutionRule == 'count' and catalog.units[data.evolution] then
                local matches = {}
                for index, unit in ipairs(state.units) do
                    if unit.name == candidate.name then table.insert(matches, index) end
                end
                local needed = data.copies or 3
                if #matches >= needed then
                    local x, y = candidate.x, candidate.y
                    for index = needed, 1, -1 do table.remove(state.units, matches[index]) end
                    local evolved = Rules.newUnit(data.evolution)
                    evolved.x, evolved.y = x, y
                    table.insert(state.units, evolved)
                    changed = true
                    break
                end
            end
        end
    end
end

function Rules.move(state, id, x, y)
    if type(id) ~= 'number' or type(x) ~= 'number' or type(y) ~= 'number'
        or x ~= math.floor(x) or y ~= math.floor(y)
        or x < 1 or x > Rules.Width or y < 0 or y > 3 then return false end
    local unit, occupant
    for _, current in ipairs(state.units) do
        if current.id == id then unit = current end
        if current.x == x and current.y == y then occupant = current end
    end
    if not unit then return false end
    if unit.y == 0 and y > 0 and (not occupant or occupant.y == 0)
        and Rules.deployed(state) >= state.level then return false end
    if occupant then occupant.x, occupant.y = unit.x, unit.y end
    unit.x, unit.y = x, y
    return true
end

function Rules.synergies(units, catalog)
    local counts, families = {}, {}
    for _, unit in ipairs(units) do
        if unit.y > 0 then
            local data = catalog.units[unit.name]
            if not families[data.family] then
                families[data.family] = true
                for _, kind in ipairs(data.types) do counts[kind] = (counts[kind] or 0) + 1 end
            end
        end
    end
    return counts
end

-- Initial port: basic attacks and movement. Named abilities/passives are metadata only.
function Rules.battle(left, right, catalog)
    local fighters = {}
    for team, units in ipairs({left, right}) do
        for _, unit in ipairs(units) do
            if unit.y > 0 then
                local data = catalog.units[unit.name]
                table.insert(fighters, {id = tostring(team)..':'..unit.id, name = unit.name,
                    team = team, x = unit.x, y = team == 1 and unit.y or 7-unit.y,
                    hp = data.hp, maxHp = data.hp, attack = data.attack,
                    defense = data.defense, range = data.range, cooldown = 0,
                    interval = math.max(1, math.floor(100 / math.max(1, data.speed)))})
            end
        end
    end
    return {fighters = fighters, tick = 0, finished = false, winner = 0}
end

function Rules.step(battle)
    if battle.finished then return end
    battle.tick += 1
    local occupied = {}
    for _, f in ipairs(battle.fighters) do
        if f.hp > 0 then occupied[f.x..':'..f.y] = true end
    end
    for _, fighter in ipairs(battle.fighters) do
        if fighter.hp > 0 then
            local target, distance = nil, math.huge
            for _, enemy in ipairs(battle.fighters) do
                local d = math.abs(enemy.x-fighter.x) + math.abs(enemy.y-fighter.y)
                if enemy.team ~= fighter.team and enemy.hp > 0 and d < distance then
                    target, distance = enemy, d
                end
            end
            if target then
                fighter.cooldown -= 1
                if distance <= fighter.range and fighter.cooldown <= 0 then
                    target.hp = math.max(0, target.hp - math.max(1,
                        math.floor(fighter.attack * 100 / (100 + target.defense*5))))
                    fighter.cooldown = fighter.interval
                    if target.hp == 0 then occupied[target.x..':'..target.y] = nil end
                elseif distance > fighter.range then
                    local bestX, bestY, best = fighter.x, fighter.y, distance
                    for _, direction in ipairs({{1,0},{-1,0},{0,1},{0,-1}}) do
                        local x, y = fighter.x+direction[1], fighter.y+direction[2]
                        local d = math.abs(x-target.x)+math.abs(y-target.y)
                        if x >= 1 and x <= 8 and y >= 1 and y <= 6
                            and not occupied[x..':'..y] and d < best then
                            bestX, bestY, best = x, y, d
                        end
                    end
                    occupied[fighter.x..':'..fighter.y] = nil
                    fighter.x, fighter.y = bestX, bestY
                    occupied[bestX..':'..bestY] = true
                end
            end
        end
    end
    local alive = {0,0}
    for _, f in ipairs(battle.fighters) do if f.hp > 0 then alive[f.team] += 1 end end
    if alive[1] == 0 or alive[2] == 0 or battle.tick >= 120 then
        battle.finished = true
        battle.winner = alive[1] == 0 and (alive[2] == 0 and 0 or 2)
            or (alive[2] == 0 and 1 or 0)
    end
end
return Rules
