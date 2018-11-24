{
---------------------------------------------------------------------------
-- threats.lua
-- Displays monster threat information in a similar manner to Online tiles.
-- Can be configured to cause a show_more when encountering dangerous monsters.
---------------------------------------------------------------------------

-- If fewer than N monsters of threat level M appear on screen at the same time, and the maximum threat level is M, then set the maximum threat level to 0
DANGER_THRESHOLD_DANGEROUS = 2              -- Fewer than 2 Dangerous Enemies = SAFE
-- (THEN, ) If N or more monsters of threat level M appear on screen at the same time, and the maximum threat level is M, then increase the maximum threat level by 1
DANGER_GROUP_EASY = 5                       -- 5 or more Weak enemies = DANGEROUS
DANGER_GROUP_DANGEROUS = 3                  -- 3 or more Dangerous enemies = EXTREMELY DANGEROUS

 -- Contains information about the monsters we're seeing and their per-type counts.
spotted_mons = { }
 -- Returns the threat level of a monster at the given coordinates
local function get_mons_threat(dx,dy)
    m = monster.get_monster_at(dx,dy)
    -- Ignore neutrals/friendlies, plants/fungi and targets behind glass walls (has a few edge cases but it's good enough)
    if not m or m:attitude() > 0 or m:is_firewood() or not you.see_cell_no_trans(dx, dy) then
        return -1
    end
    return m:threat()
end
-- Helper that returns the length of dictionaries as well
local function tbl_len(t)
    local count = 0
    for _ in pairs(t) do count = count + 1 end
    return count
end

-- Updates spotted_mons and returns the highest danger level.
local function most_dangerous_mons_in_los()
    spotted_mons = { }
    local los_radius = you.los()
    local x, y
    local max = -1
    -- If too many weaklings are on screen, we may return a higher danger level
    local easy_count = 0
    local dangerous_count = 0
    local extremely_dangerous_count = 0
    -- For each tile in LOS
    for x = -los_radius,los_radius do
        for y = -los_radius,los_radius do
            t = get_mons_threat(x, y)
            -- If there's a monster, add it to spotted_mons and think about dupes later
            if t >= 0 then
                m = monster.get_monster_at(x, y)
                table.insert(spotted_mons, m)
            end
            -- Also keep track of the maximum danger level obviously
            if t >= max then
                max = t
            end
            if t == 3 then
                extremely_dangerous_count = extremely_dangerous_count + 1
            elseif t == 2 then
                dangerous_count = dangerous_count + 1
            elseif t == 1 then
                easy_count = easy_count + 1
            end
        end
    end

    local hp_pct = get_hp_pct()
    local DTD = hp_pct > 0.5 and DANGER_THRESHOLD_DANGEROUS or math.ceil(DANGER_THRESHOLD_DANGEROUS / 2)
    local DGD = hp_pct > 0.5 and DANGER_GROUP_DANGEROUS or math.ceil(DANGER_GROUP_DANGEROUS / 2)
    local DGE = hp_pct > 0.5 and DANGER_GROUP_EASY or math.ceil(DANGER_GROUP_EASY / 2)

    -- If the following threshold is set appropriately, you can ignore small packs of Dangerous enemies.
    if max == 2 and dangerous_count <= DTD then
        max = 1
    end
    -- Lots of Easy enemies can raise the danger level from Safe to Dangerous, but not higher.
    -- Lots of Dangerous enemies can raise the danger level from Dangerous to Extremely Dangerous, but not higher.
    if (max < 3 and dangerous_count >= DGD) or (max < 2 and easy_count >= DGE) then
        max = max + 1
    end

    unique_mons = { }
    -- Remove duplicates by keeping track of their count.
    -- (note: only the most recent monster instance is kept, but we only care about its generalities)
    for k, v in pairs(spotted_mons) do
        local name = v:name()
        if unique_mons[name] == nil then
            unique_mons[name] = { monster = v, count = 1 }
        else
            unique_mons[name] = { monster = v, count = unique_mons[name].count + 1 }
        end
    end
    spotted_mons = unique_mons
    return max
end

function danger_to_glyph(d)
    if d < 0 then
        return "<darkgray>S</darkgray>"
    elseif d == 0 then
        return "<lightgray>S</lightgray>"
    elseif d == 1 then
        return "<white>S</white>"
    elseif d == 2 then
        return "<yellow>D</yellow>"
    elseif d == 3 then
        return "<lightred>E</lightred>"
    end
end

-- If we spot a dangerous enemy, alert the player. You may wish to add this to your rc:
-- force_more_message += You're in danger!
-- force_more_message += You're in extreme danger!
prev_threat_level = -1
function alert_if_in_danger()
    danger = most_dangerous_mons_in_los()
    local was_in_extreme_danger = false
    if prev_threat_level ~= danger then
        if danger < prev_threat_level and danger < 2 and prev_threat_level >= 2 then
            print("You feel safer.")
        elseif danger < prev_threat_level and danger == 2 then
            was_in_extreme_danger = true
        end
        prev_threat_level = danger
    else
        prev_threat_level = danger
        return
    end

    if danger < 2 then
        return
    end

    if danger == 2 then
        if was_in_extreme_danger then
            -- Can be used to prevent force_more if you just deescalated from extremely dangerous
            print("<yellow>You're still in danger!</yellow>")
        else
            print("<yellow>You're in danger!</yellow>")
        end
    elseif danger == 3 then
        print("<lightred>You're in extreme danger!</lightred>")
    end
    print_mons_in_sight()
end

-- Prints a nice colored list of every type of monster we can see and the respective counts.
-- You can bind this to a custom key, but it's also called when you're in danger automatically.
function print_mons_in_sight()
    if tbl_len(spotted_mons) == 0 then
        print("There are no monsters in sight.")
        return
    end

    local str = "Monsters you can see: "
    for k, v in spairs(spotted_mons, function(t, a, b) return t[a].monster:threat() > t[b].monster:threat() end) do
        local m = v.count .. "x " .. v.monster:name()
        local t = v.monster:threat()
        if t < 2 then
        str = str .. m .. ", "
        elseif t == 2 then
        str = str .. "<yellow>" .. m .. "</yellow>" .. ", "
        elseif t == 3 then
        str = str .. "<lightred>" .. m .. "</lightred>" .. ", "
        end
    end
    print(string.sub(str, 0, -3) .. ".")
end

function print_threats_header()
    print("<lightcyan>----- Using G3Kappa's Threats Warnings -----</lightcyan>")
    print("<lightgray>    Max. # of " .. danger_to_glyph(2) .. " enemies to consider " .. danger_to_glyph(1) .. ": " .. DANGER_THRESHOLD_DANGEROUS .. "</lightgray>")
    print("<lightgray>    Min. # of " .. danger_to_glyph(1) .. " enemies to consider " .. danger_to_glyph(2) .. ": " .. DANGER_GROUP_EASY .. "</lightgray>")
    print("<lightgray>    Min. # of " .. danger_to_glyph(2) .. " enemies to consider " .. danger_to_glyph(3) .. ": " .. DANGER_GROUP_DANGEROUS .. "</lightgray>")
    print("<lightcyan>----- Thresholds are halved at 50% HP. -----</lightcyan>")
end

threat_initialized = false
function threats_ready()
    -- Initialize on first turn so that custom options can be loaded first
    if not threat_initialized then
        threat_initialized = true
        print_threats_header()
    end
    alert_if_in_danger()
end

function global_threat_level()
    return prev_threat_level
end

local function set_danger_group_easy(key, value, mode)
    DANGER_GROUP_EASY = tonumber(value) or 5
end
local function set_danger_group_dangerous(key, value, mode)
    DANGER_GROUP_DANGEROUS = tonumber(value) or 3
end
local function set_danger_threshold_dangerous(key, value, mode)
    DANGER_THRESHOLD_DANGEROUS = tonumber(value) or 2
end

chk_lua_option.danger_group_easy = set_danger_group_easy
chk_lua_option.danger_group_dangerous = set_danger_group_dangerous
chk_lua_option.danger_threshold_dangerous = set_danger_threshold_dangerous
}