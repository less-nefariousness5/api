-- =============================================================================
-- SoD Rogue Backstab/Cutthroat — rotation logic
-- =============================================================================
-- Leveling-adaptive (1-60). Priority list transcribed from the wowsims SoD
-- "Slaughter_Cutthroat_60" APL and made level/rune aware.
--
-- Governing rules (slow Classic combat, 20 energy / 2s tick):
--   * build to the finisher CP threshold, dump Eviscerate, never overcap energy
--   * keep Slice and Dice up (top priority once a combo point exists)
--   * Backstab is the builder; fire the free Ambush whenever Cutthroat procs
--   * Backstab self-adapts: usable from the front once Cutthroat removes the
--     positional requirement, otherwise only fires when behind the target
-- =============================================================================

local izi  = require("common/izi_sdk")
local IDS  = require("rotations/sod_rogue_backstab/ids")
local menu = require("rotations/sod_rogue_backstab/menu")

local R = {}

-- ---- build spell / item wrappers once ------------------------------------
local unpack = table.unpack or unpack   -- WoW Lua 5.1 uses global unpack
local function spell(list)
    if type(list) == "table" then return izi.spell(unpack(list)) end
    return izi.spell(list)
end

local S = {
    backstab        = spell(IDS.backstab),
    sinister        = spell(IDS.sinister_strike),
    saber_slash     = spell(IDS.saber_slash),
    ambush          = spell(IDS.ambush),
    eviscerate      = spell(IDS.eviscerate),
    slice_and_dice  = spell(IDS.slice_and_dice),
    rupture         = spell(IDS.rupture),
    adrenaline_rush = spell(IDS.adrenaline_rush),
    blade_flurry    = spell(IDS.blade_flurry),
    cold_blood      = spell(IDS.cold_blood),
    evasion         = spell(IDS.evasion),
    gouge           = spell(IDS.gouge),
    kick            = spell(IDS.kick),
}

local function item(id) return izi.item(id) end
local I = {
    thistle_tea = item(IDS.item_thistle_tea),
}

-- ---- small helpers --------------------------------------------------------
local function learned(sp) return sp and sp:is_learned() end

-- seconds of a buff/debuff remaining (0 if absent / nil-safe)
local function buff_remains(unit, spec)
    if not unit then return 0 end
    return unit:buff_remains(spec) or 0
end
local function debuff_remains(unit, spec)
    if not unit then return 0 end
    return unit:debuff_remains(spec) or 0
end

-- pick the active target
local function get_target()
    local t
    if menu.use_ts:get() then t = izi.ts(1) end
    t = t or izi.target()
    if not t or not t:is_valid_enemy() then return nil end
    return t
end

-- can we land Backstab right now? (Cutthroat removes the behind requirement)
local function backstab_ready(me, target)
    if not learned(S.backstab) then return false end
    if menu.assume_behind:get() then return true end
    if not S.backstab:requires_back() then return true end   -- Cutthroat (or no positional gate)
    return me:is_behind(target)
end

-- the frontal builder fallback (Saber Slash rune if present, else Sinister Strike)
local function frontal_builder()
    if learned(S.saber_slash) then return S.saber_slash, "Saber Slash" end
    return S.sinister, "Sinister Strike"
end

-- ---------------------------------------------------------------------------
-- COOLDOWNS (only while the burst keybind is held / auto, and not stealthed)
-- ---------------------------------------------------------------------------
local function do_cooldowns(me, target, cp)
    if me:stealth_up() then return false end
    local burst = menu.burst:is_active() or menu.auto_cooldowns:get()
    if not burst then return false end

    -- Cold Blood paired with an imminent finisher (guaranteed-crit Eviscerate)
    if menu.cold_blood:get() and learned(S.cold_blood) and cp >= menu.finisher_cp:get()
       and S.cold_blood:cooldown_up() then
        if S.cold_blood:cast_safe(me, "Cold Blood", { skip_gcd = true }) then return true end
    end

    if menu.auto_cooldowns:get() then
        if learned(S.adrenaline_rush) and S.adrenaline_rush:cooldown_up()
           and S.adrenaline_rush:cast_safe(me, "Adrenaline Rush", { skip_gcd = true }) then return true end

        local want_bf = learned(S.blade_flurry) and S.blade_flurry:cooldown_up()
        if want_bf and menu.aoe:get() and (#(me:get_enemies_in_melee_range(8) or {}) >= 2) then
            if S.blade_flurry:cast_safe(me, "Blade Flurry", { skip_gcd = true }) then return true end
        end
    end
    return false
end

-- ---------------------------------------------------------------------------
-- DEFENSIVES / INTERRUPTS
-- ---------------------------------------------------------------------------
local function do_defensives(me, target)
    if not menu.auto_defensive:get() then return false end
    local hp = me:get_health_percentage()
    if hp <= menu.evasion_hp:get() and learned(S.evasion) and S.evasion:cooldown_up() then
        if S.evasion:cast_safe(me, "Evasion", { skip_gcd = true }) then return true end
    end
    if hp <= menu.potion_hp:get() and izi.use_best_health_potion_safe then
        if izi.use_best_health_potion_safe({ skip_gcd = true }) then return true end
    end
    return false
end

local function do_interrupt(me, target)
    if not menu.auto_kick:get() then return false end
    if not target:is_casting() and not target:is_channeling() then return false end
    if learned(S.kick) and S.kick:cooldown_up() then
        return S.kick:cast_safe(target, "Kick", { skip_gcd = true })
    end
    return false
end

-- ---------------------------------------------------------------------------
-- MAIN TICK
-- ---------------------------------------------------------------------------
local function tick()
    izi.on_update()                      -- drive the SDK once per frame

    if not menu.enabled:is_active() then return end

    local me = izi.me()
    if not me or me:is_dead_or_ghost() then return end

    local target = get_target()
    if not target then return end

    -- defensives are allowed even slightly out of melee
    if do_defensives(me, target) then return end

    if not target:is_in_melee_range(5) then return end
    if not me:can_attack(target) then return end

    if do_interrupt(me, target) then return end

    local cp     = me:combo_points_current()
    local energy = me:energy_current()
    local emax   = me:energy_max()
    local ttd    = target:time_to_die() or 999
    local finish_cp = menu.finisher_cp:get()

    -- Thistle Tea: rescue energy starvation while still building
    if menu.thistle_tea:get() and I.thistle_tea and energy <= 15 and cp < finish_cp
       and I.thistle_tea:cooldown_up() and I.thistle_tea:in_inventory() then
        if I.thistle_tea:use_self_safe("Thistle Tea", { skip_gcd = true }) then return end
    end

    if do_cooldowns(me, target, cp) then return end

    -- Free no-stealth Ambush from the Cutthroat proc
    if me:has_buff(IDS.cutthroat_proc) and learned(S.ambush) then
        if S.ambush:cast_safe(target, "Ambush (Cutthroat)") then return end
    end

    -- End-of-fight: dump combo points before the target dies (beats maintenance)
    if learned(S.eviscerate) and ttd <= 3 and cp >= 2 then
        if S.eviscerate:cast_safe(target, "Eviscerate (dump)") then return end
    end

    -- Slice and Dice uptime (skip manual upkeep if Cut-to-the-Chase auto-refreshes it)
    if menu.maintain_snd:get() and not menu.cut_to_chase:get()
       and learned(S.slice_and_dice) and cp >= 1 then
        if buff_remains(me, IDS.aura_slice_and_dice) < 2 then
            if S.slice_and_dice:cast_safe(me, "Slice and Dice") then return end
        end
    end

    -- Rupture for bleed damage + Carnage synergy (value-gated on TTD)
    if menu.maintain_rup:get() and learned(S.rupture)
       and cp >= 4 and ttd >= menu.rupture_min_ttd:get() then
        if debuff_remains(target, IDS.debuff_rupture) < 2 then
            if S.rupture:cast_safe(target, "Rupture") then return end
        end
    end

    -- Finisher: Eviscerate at the CP threshold, or at 4 CP if energy is about to
    -- overcap (the dying-target dump is handled higher up).
    if learned(S.eviscerate) then
        if cp >= finish_cp or (cp >= 4 and energy >= (emax - 20)) then
            if S.eviscerate:cast_safe(target, "Eviscerate") then return end
        end
    end

    -- Builder: keep a small reactive energy buffer (energy_pool) before pressing.
    if cp < 5 and energy >= menu.energy_pool:get() then
        if backstab_ready(me, target) and S.backstab:is_usable() then
            if S.backstab:cast_safe(target, "Backstab") then return end
        else
            local b, name = frontal_builder()
            if learned(b) and b:is_usable() then
                if b:cast_safe(target, name) then return end
            end
        end
    end
end

-- pcall-wrapped so a transient API hiccup never hard-stops the callback
function R.on_update()
    local ok, err = pcall(tick)
    if not ok and izi and izi.printf then
        izi.printf("[sod_rogue_bs] tick error: %s", tostring(err))
    end
end

function R.on_render_menu()
    menu.render()
end

return R
