-- =============================================================================
-- SoD Rogue Backstab/Cutthroat — settings menu (ow_menu_api)
-- =============================================================================
-- Elements are created ONCE at load. M.render() is called from the
-- register_on_render_menu_callback. Getters are read each frame in rotation.lua.
-- =============================================================================

local menu_api = require("common/ow_menu_api")

local M = {}

local P = "sod_rogue_bs_"  -- persistence-id prefix (keep unique across plugins)

-- ---- General -------------------------------------------------------------
M.enabled        = menu_api.new_keybind(true, true, 0x06, P .. "enabled")   -- toggle on/off (default key X2 mouse)
M.burst          = menu_api.new_keybind(false, false, 0x05, P .. "burst")   -- hold for cooldowns (default key X1 mouse)
M.aoe            = menu_api.new_checkbox(P .. "aoe", false)                  -- enable AoE/cleave logic
M.aoe_threshold  = menu_api.new_slider(2, 6, 3, P .. "aoe_threshold")       -- enemies for full AoE finisher (2 = cleave only)
M.use_ts         = menu_api.new_checkbox(P .. "use_ts", true)               -- pick target via target-selector
M.tank_mode      = menu_api.new_checkbox(P .. "tank_mode", false)           -- threat priority (Just a Flesh Wound / Blade Dance build)

-- ---- Core rotation -------------------------------------------------------
M.finisher_cp    = menu_api.new_slider(3, 5, 5, P .. "finisher_cp")         -- combo points before Eviscerate
M.energy_pool    = menu_api.new_slider(0, 60, 25, P .. "energy_pool")       -- min energy kept before a builder
M.assume_behind  = menu_api.new_checkbox(P .. "assume_behind", false)       -- treat Backstab as always usable (pre-Cutthroat manual positioning)

-- ---- Maintenance ---------------------------------------------------------
M.maintain_snd   = menu_api.new_checkbox(P .. "maintain_snd", true)         -- keep Slice and Dice up
M.cut_to_chase   = menu_api.new_checkbox(P .. "cut_to_chase", false)        -- Cut-to-the-Chase rune equipped (Eviscerate auto-refreshes SnD)
M.maintain_rup   = menu_api.new_checkbox(P .. "maintain_rup", true)         -- keep Rupture up (Carnage synergy)
M.rupture_min_ttd= menu_api.new_slider(5, 30, 8, P .. "rup_ttd")            -- only Rupture if target lives >= N s
M.maintain_ea    = menu_api.new_checkbox(P .. "maintain_ea", false)         -- keep Expose Armor up (group armor debuff / Sebacious seed)
M.ea_min_ttd     = menu_api.new_slider(5, 30, 15, P .. "ea_ttd")            -- only Expose Armor if target lives >= N s

-- ---- Cooldowns -----------------------------------------------------------
M.auto_cooldowns = menu_api.new_checkbox(P .. "auto_cd", true)              -- AR / Blade Flurry / Cold Blood
M.cold_blood     = menu_api.new_checkbox(P .. "cold_blood", true)           -- pair Cold Blood with finisher
M.thistle_tea    = menu_api.new_checkbox(P .. "thistle", true)              -- Thistle Tea when energy starved
M.vanish_burst   = menu_api.new_checkbox(P .. "vanish_burst", false)        -- Vanish -> Ambush burst (refreshes Master of Subtlety); drops threat
M.auto_prep      = menu_api.new_checkbox(P .. "auto_prep", false)           -- Preparation to reset Vanish/Cold Blood for a second burst
M.use_sapper     = menu_api.new_checkbox(P .. "use_sapper", false)          -- Goblin Sapper Charge in AoE/burst (self-damaging)

-- ---- Stealth openers -----------------------------------------------------
M.stealth_openers= menu_api.new_checkbox(P .. "stealth_open", true)         -- Premeditation -> opener when stealthed

-- ---- Consumables / out of combat ----------------------------------------
M.auto_consumes  = menu_api.new_checkbox(P .. "auto_consume", false)        -- auto elixirs/flask (out of combat, self-use)
M.auto_poison    = menu_api.new_checkbox(P .. "auto_poison", false)         -- re-coat main-hand poison/sharpening (timer-based; VERIFY apply)
M.reapply_mins   = menu_api.new_slider(5, 60, 25, P .. "reapply_mins")      -- out-of-combat re-apply interval (minutes)

-- ---- Defensives ----------------------------------------------------------
M.auto_defensive = menu_api.new_checkbox(P .. "auto_def", true)             -- Evasion / healing potion
M.evasion_hp     = menu_api.new_slider(10, 60, 35, P .. "evasion_hp")       -- Evasion below this HP%
M.potion_hp      = menu_api.new_slider(10, 60, 25, P .. "potion_hp")        -- healing potion below this HP%
M.free_action    = menu_api.new_checkbox(P .. "free_action", false)         -- Free Action Potion when rooted/stunned

-- ---- Interrupts ----------------------------------------------------------
M.auto_kick      = menu_api.new_checkbox(P .. "auto_kick", true)            -- Kick interruptible casts
M.gouge_interrupt= menu_api.new_checkbox(P .. "gouge_int", true)            -- Gouge as a fallback interrupt when Kick is down

-- ---- Automation (attack / stealth / loot) --------------------------------
M.auto_attack    = menu_api.new_checkbox(P .. "auto_attack", true)          -- ensure white swings start on a new target
M.auto_stealth   = menu_api.new_checkbox(P .. "auto_stealth", false)        -- auto Stealth out of combat near enemies
M.stealth_range  = menu_api.new_slider(8, 40, 25, P .. "stealth_range")     -- enemy proximity (yd) that triggers auto-stealth
M.auto_loot      = menu_api.new_checkbox(P .. "auto_loot", false)           -- loot nearby corpses out of combat
M.loot_range     = menu_api.new_slider(3, 12, 5, P .. "loot_range")         -- corpse interact range (yd)
M.clear_dead     = menu_api.new_checkbox(P .. "clear_dead", true)           -- drop target once it is dead/looted

function M.render()
    menu_api.begin_frame()
    menu_api.header("SoD Rogue - Backstab/Cutthroat")
    M.enabled:render("Enabled (toggle)")
    M.burst:render("Burst cooldowns (hold)")
    M.use_ts:render("Use target selector")
    M.aoe:render("AoE / cleave mode")
    M.aoe_threshold:render("AoE finisher at N enemies")
    M.tank_mode:render("Tank mode (threat priority)")

    menu_api.separator()
    menu_api.header("Core")
    M.finisher_cp:render("Finisher at combo points")
    M.energy_pool:render("Min energy before builder")
    M.assume_behind:render("Assume Backstab usable (manual positioning)")

    menu_api.separator()
    menu_api.header("Maintenance")
    M.maintain_snd:render("Maintain Slice and Dice")
    M.cut_to_chase:render("Cut-to-the-Chase rune (auto SnD)")
    M.maintain_rup:render("Maintain Rupture")
    M.rupture_min_ttd:render("Rupture min target TTD (s)")
    M.maintain_ea:render("Maintain Expose Armor")
    M.ea_min_ttd:render("Expose Armor min target TTD (s)")

    menu_api.separator()
    menu_api.header("Cooldowns")
    M.auto_cooldowns:render("Auto Adrenaline Rush / Blade Flurry")
    M.cold_blood:render("Cold Blood + finisher")
    M.thistle_tea:render("Thistle Tea when energy starved")
    M.vanish_burst:render("Vanish -> Ambush burst")
    M.auto_prep:render("Preparation (reset for 2nd burst)")
    M.use_sapper:render("Goblin Sapper in AoE/burst")

    menu_api.separator()
    menu_api.header("Stealth")
    M.stealth_openers:render("Auto stealth openers")

    menu_api.separator()
    menu_api.header("Consumables (out of combat)")
    M.auto_consumes:render("Auto elixirs / flask")
    M.auto_poison:render("Auto re-coat poison / sharpening (VERIFY)")
    M.reapply_mins:render("Re-apply interval (min)")

    menu_api.separator()
    menu_api.header("Defensives / Utility")
    M.auto_defensive:render("Auto defensives")
    M.evasion_hp:render("Evasion below HP%")
    M.potion_hp:render("Healing potion below HP%")
    M.free_action:render("Free Action Potion when rooted/stunned")
    M.auto_kick:render("Auto Kick interrupts")
    M.gouge_interrupt:render("Gouge fallback interrupt")

    menu_api.separator()
    menu_api.header("Automation")
    M.auto_attack:render("Ensure auto-attack on new target")
    M.auto_stealth:render("Auto Stealth near enemies (out of combat)")
    M.stealth_range:render("Auto-stealth enemy range (yd)")
    M.auto_loot:render("Auto loot corpses (out of combat)")
    M.loot_range:render("Loot range (yd)")
    M.clear_dead:render("Clear target when dead/looted")
end

return M
