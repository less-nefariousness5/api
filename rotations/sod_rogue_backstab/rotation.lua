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
    premeditation   = spell(IDS.premeditation),
    cheap_shot      = spell(IDS.cheap_shot),
    garrote         = spell(IDS.garrote),
}

local function item(id) return izi.item(id) end
local I = {
    thistle_tea = item(IDS.item_thistle_tea),
    elixir_agi  = item(IDS.item_elixir_mongoose),
    elixir_ap   = item(IDS.item_winterfall_firewater),
    flask       = item(IDS.item_flask_nightmares),
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

-- can this positional spell land right now? (Cutthroat removes the behind gate)
local function can_position(sp, me, target)
    if not learned(sp) then return false end
    if menu.assume_behind:get() then return true end
    if not sp:requires_back() then return true end           -- Cutthroat (or no positional gate)
    return me:is_behind(target)
end

local function backstab_ready(me, target)
    return can_position(S.backstab, me, target) and S.backstab:is_usable()
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
-- STEALTH OPENERS  (Premeditation -> Ambush behind / Cheap Shot / Garrote)
-- ---------------------------------------------------------------------------
local function do_stealth_opener(me, target, cp)
    if not menu.stealth_openers:get() then return false end
    if not me:stealth_up() then return false end

    -- Premeditation first: +2 CP, off-GCD, does not break stealth
    if learned(S.premeditation) and cp < 2 and S.premeditation:cooldown_up() then
        if S.premeditation:cast_safe(me, "Premeditation", { skip_gcd = true }) then return true end
    end
    -- Opener: Ambush if we can land it (dagger + behind/Cutthroat), else Cheap Shot, else Garrote
    if can_position(S.ambush, me, target) and S.ambush:is_usable() then
        if S.ambush:cast_safe(target, "Ambush (opener)") then return true end
    elseif learned(S.cheap_shot) and S.cheap_shot:is_usable() then
        if S.cheap_shot:cast_safe(target, "Cheap Shot (opener)") then return true end
    elseif can_position(S.garrote, me, target) and S.garrote:is_usable() then
        if S.garrote:cast_safe(target, "Garrote (opener)") then return true end
    end
    return false
end

-- ---------------------------------------------------------------------------
-- OUT OF COMBAT: elixirs/flask (clean self-use) + poison/sharpening (timer)
-- !! VERIFY !! Weapon-coat application (poison/sharpening) is not cleanly
-- exposed by this API, so it is timer-based and assumes use_item auto-applies
-- to the main hand. Confirm the apply mechanic and off-hand handling in-client.
-- ---------------------------------------------------------------------------
local last_apply = {}   -- item/spell id -> izi.now() seconds
local function now_s() return (izi.now and izi.now()) or 0 end

local function timed(id, interval, fn)
    if not id then return false end
    local t = now_s()
    if last_apply[id] and (t - last_apply[id]) < interval then return false end
    if fn() then last_apply[id] = t; return true end
    return false
end

local function do_out_of_combat(me)
    local interval = (menu.reapply_mins:get() or 25) * 60

    if menu.auto_consumes:get() then
        -- self-use consumables; only re-apply when their buff is absent if we can
        -- detect it, otherwise on the timer.
        if I.flask and timed(IDS.item_flask_nightmares, interval, function()
            return I.flask:in_inventory() and I.flask:is_usable()
               and I.flask:use_self_safe("Flask", { skip_gcd = true }) end) then return true end
        if I.elixir_agi and timed(IDS.item_elixir_mongoose, interval, function()
            return I.elixir_agi:in_inventory() and I.elixir_agi:is_usable()
               and I.elixir_agi:use_self_safe("Agi Elixir", { skip_gcd = true }) end) then return true end
        if I.elixir_ap and timed(IDS.item_winterfall_firewater, interval, function()
            return I.elixir_ap:in_inventory() and I.elixir_ap:is_usable()
               and I.elixir_ap:use_self_safe("AP Elixir", { skip_gcd = true }) end) then return true end
    end

    if menu.auto_poison:get() then
        -- main-hand poison re-coat (timer-based; relies on client auto-apply to MH)
        local mh_poison = IDS.poison_instant[#IDS.poison_instant]   -- highest rank
        if timed(mh_poison, interval, function()
            return core.input and core.input.use_item and core.input.use_item(mh_poison) end) then return true end
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

    -- out-of-combat upkeep (elixirs/flask/poison) before we engage
    if not me:affecting_combat() and me.is_standing_still and me:is_standing_still() then
        if do_out_of_combat(me) then return end
    end

    if not target:is_in_melee_range(5) then return end
    if not me:can_attack(target) then return end

    if do_interrupt(me, target) then return end

    local cp     = me:combo_points_current()

    -- stealth opener takes over while stealthed
    if do_stealth_opener(me, target, cp) then return end
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
        if backstab_ready(me, target) then
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
