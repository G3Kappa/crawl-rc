{
---------------------------------------------------------------------------
-- bootstrap.lua
-- Loads my other scripts and ensures proper control flow.
---------------------------------------------------------------------------
function print(str)
    crawl.mpr(str)
    crawl.flush_prev_message()
end

function get_hp_pct()
    local hp, maxhp = you.hp()
    return hp / maxhp
end

function can_quaff()
    if you.race() == "Mummy" or you.berserk() then
        return false
    end
    local tran = you.transform()
    if tran == "Necromutation" or tran == "Tree Form" or tran == "Wisp Form" or tran == "Bat Form" then
        return false
    end
    return true
end

function has_item(name)
    local inv = items.inventory()
    for _, it in ipairs(inv) do
        if it.name() == name then return true, it end
    end
    return false, nil
end

-- Helper that iterates a dictionary in a specific order
function spairs(t, order)
    -- collect the keys
    local keys = {}
    for k in pairs(t) do keys[#keys+1] = k end

    -- if order function given, sort by it by passing the table and keys a, b,
    -- otherwise just sort the keys 
    if order then
        table.sort(keys, function(a,b) return order(t, a, b) end)
    else
        table.sort(keys)
    end

    -- return the iterator function
    local i = 0
    return function()
        i = i + 1
        if keys[i] then
            return keys[i], t[keys[i]]
        end
    end
end

function ready()
    threats_ready()
    antipanic_ready()
end
}