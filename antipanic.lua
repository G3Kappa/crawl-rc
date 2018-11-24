{
---------------------------------------------------------------------------
-- antipanic.lua
-- Tries to pre-emptively save your hide before you mess up too bad.
---------------------------------------------------------------------------

-- Autoquaff a healing potion whenever the next tick of poison would bring you below N% HP
AUTOQUAFF_POISONED_MAX_HEALTH = 75
-- Prevent the above unless global_threat_level() >= N
-- (Possible values: -1 [quaff always], 0 [quaff always if there are enemies], 1 [quaff @ Safe], 2 [quaff @ Danger], 3 [quaff @ Extreme Danger])
AUTOQUAFF_POISONED_MIN_DANGER = 1
-- Autoread unidentified scrolls if you have more than N and there are no enemies in sight
AUTOIDENT_SCROLL_MIN = 2
-- Autoquaff unidentified potions if you have more than N and there are no enemies in sight
AUTOIDENT_POTION_MIN = 3

tried_to_cure_poison = false
local function autoquaff_poisoned()
    local hp_pct = get_hp_pct()
    if can_quaff() and math.floor(hp_pct * 100) <= AUTOQUAFF_POISONED_MAX_HEALTH and global_threat_level() >= AUTOQUAFF_POISONED_MIN_DANGER then
        local has_cure, cure = has_item("potion of curing")
        if has_cure then
            local letter = items.index_to_letter(cure.slot)
            print("<green>[AP]</green> Quaffing potion of curing to heal poison.")
            crawl.sendkeys("q" .. letter)
        elseif tried_to_cure_poison == false then
            print("<red>[AP]</red> Can't heal poison; no potions of curing were found/identified.")
            tried_to_cure_poison = true
        end
    else
        tried_to_cure_poison = false
    end
end

local function auto_identify()
    if global_threat_level() > 0 then return end

    local inv = items.inventory()
    for _, it in ipairs(inv) do
        if not it.fully_identified then
            local letter = items.index_to_letter(it.slot)
            if it.class() == "Scrolls" and it.quantity >= AUTOIDENT_SCROLL_MIN then
                print("<yellow>[AP]</yellow> Auto-reading unidentified scroll.")
                crawl.sendkeys("r" .. letter)
            elseif can_quaff() and it.class() == "Potions" and it.quantity >= AUTOIDENT_POTION_MIN then
                print("<yellow>[AP]</yellow> Auto-quaffing unidentified potion.")
                crawl.sendkeys("q" .. letter)
            end
        end
    end
end

function print_antipanic_header()
    print("<lightmagenta>----- Using G3Kappa's Antipanic System -----</lightmagenta>")
    print("<lightgray>    Autoheal <green>poison</green> if Health <<= <yellow>" .. AUTOQUAFF_POISONED_MAX_HEALTH .. "</yellow>%</lightgray>")
    print("<lightgray>    Autoheal <green>poison</green> if Danger >= " .. danger_to_glyph(AUTOQUAFF_POISONED_MIN_DANGER) .. "</lightgray>")
    print("<lightgray>    Autoident <yellow>scrolls</yellow> if # >= <white>" .. AUTOIDENT_SCROLL_MIN .. "</white></lightgray>")
    print("<lightgray>    Autoident <yellow>potions</yellow> if # >= <white>" .. AUTOIDENT_POTION_MIN .. "</white></lightgray>")
    print("<lightmagenta>--------------------------------------------</lightmagenta>")
end

antipanic_initialized = false
function antipanic_ready()
    if not antipanic_initialized then
        antipanic_initialized = true
        print_antipanic_header()
    end

    if you.poisoned() then
        autoquaff_poisoned()
    end

    auto_identify()
end

local function set_autoquaff_pois_health(key, value, mode)
    AUTOQUAFF_POISONED_MAX_HEALTH = tonumber(value) or 75
end
chk_lua_option.autoheal_poison_max_health = set_autoquaff_pois_health

local function set_autoquaff_pois_danger(key, value, mode)
    AUTOQUAFF_POISONED_MIN_DANGER = tonumber(value) or 0
end
chk_lua_option.autoheal_poison_min_danger = set_autoquaff_pois_danger

local function set_autoident_scroll_min(key, value, mode)
    AUTOIDENT_SCROLL_MIN = tonumber(value) or 2
end
chk_lua_option.autoident_scroll_min = set_autoident_scroll_min

local function set_autoident_potion_min(key, value, mode)
    AUTOIDENT_POTION_MIN = tonumber(value) or 3
end
chk_lua_option.autoident_potion_min = set_autoident_potion_min

}