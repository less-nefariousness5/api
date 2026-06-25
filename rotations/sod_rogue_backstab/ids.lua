-- =============================================================================
-- SoD Rogue Backstab/Cutthroat — ID tables (single source of truth)
-- =============================================================================
--
-- Pure data. No SDK dependency. rotation.lua turns these into izi.spell objects.
--
-- RANK STRATEGY (important for a 1-60 leveling rotation):
--   izi.spell(id1, id2, ...) resolves to the HIGHEST *known* rank. Passing rank
--   IDs the character has not learned is harmless -- they are ignored. So each
--   ability below lists every known rank; the same file therefore works at any
--   level without edits.
--
-- !! VERIFY !!  IDs were gathered from wowhead.com/classic + the wowsims SoD
--   simulator (live guide sites were egress-blocked during research). They are
--   best-known values. Before relying on this in-game, confirm the ranks your
--   client actually reports, especially the SoD rune/proc IDs and SoD poisons.
--   Wrong-but-unknown ranks are filtered out automatically; the only real risk
--   is an ID that collides with a *different known* spell, so spot-check.
-- =============================================================================

local IDS = {}

-- ---------------------------------------------------------------------------
-- Builders / finishers (multi-rank lists; highest known rank wins)
-- ---------------------------------------------------------------------------
IDS.backstab        = { 53, 2589, 2590, 2591, 8721, 11279, 11280, 11281, 25300, 25302 }
IDS.sinister_strike = { 1752, 1757, 1758, 1759, 1760, 8621, 11293, 11294 }
IDS.saber_slash     = { 424785 }                 -- SoD rune builder (alt to Sinister Strike)
IDS.ambush          = { 8676, 8724, 8725, 11267, 11268, 11269 }
IDS.ghostly_strike  = { 14278 }
IDS.eviscerate      = { 2098, 6760, 6761, 6762, 8623, 8624, 11299, 11300 }
IDS.slice_and_dice  = { 5171, 6774 }
IDS.rupture         = { 1943, 8639, 8640, 11273, 11274, 11275 }
IDS.crimson_tempest = { 436611 }                 -- SoD rune: AoE bleed finisher (VERIFY id; unknown id is auto-filtered)
IDS.expose_armor    = { 8647, 8649, 8650, 11197, 11198 }
IDS.kidney_shot     = { 408, 8643 }
IDS.envenom_rune    = { 399963 }                 -- SoD Envenom (rune); not baseline in Classic

-- ---------------------------------------------------------------------------
-- Stealth / openers
-- ---------------------------------------------------------------------------
IDS.stealth         = { 1784, 1785, 1786, 1787 }
IDS.premeditation   = { 14183 }                  -- +2 CP opener (talent)
IDS.cheap_shot      = { 1833 }
IDS.garrote         = { 703, 8631, 8632, 8633, 11289, 11290 }
IDS.vanish          = { 1856, 1857 }

-- ---------------------------------------------------------------------------
-- Cooldowns / utility
-- ---------------------------------------------------------------------------
IDS.adrenaline_rush = { 13750 }
IDS.blade_flurry    = { 13877 }
IDS.cold_blood      = { 14177 }
IDS.preparation     = { 14185 }
IDS.evasion         = { 5277 }
IDS.sprint          = { 2983, 8696, 11305 }
IDS.gouge           = { 1776, 1777, 8629, 11285, 11286 }
IDS.kick            = { 1766, 1767, 1768, 1769 }
IDS.blind           = { 2094 }

-- ---------------------------------------------------------------------------
-- SoD rune-granted spells / auras to TRACK or detect (single IDs, no ranks)
-- ---------------------------------------------------------------------------
IDS.cutthroat_proc       = 462707   -- free no-stealth Ambush proc aura (10s) from Backstab
IDS.master_of_subtlety   = 425096   -- damage buff aura (VERIFY: triggered-buff id may differ)
IDS.cut_to_the_chase     = 432271   -- rune: Eviscerate refreshes SnD to full
IDS.carnage              = 432276   -- rune: +20% vs bleeding target
IDS.slaughter_from_shadows = nil    -- VERIFY id; used for tuning only, not cast

-- ---------------------------------------------------------------------------
-- Buff/debuff aura specs (in Classic, auras usually share the cast spell id)
-- ---------------------------------------------------------------------------
IDS.aura_slice_and_dice = IDS.slice_and_dice
IDS.aura_stealth        = IDS.stealth
IDS.aura_blade_flurry   = IDS.blade_flurry
IDS.aura_adrenaline     = IDS.adrenaline_rush
IDS.aura_cold_blood     = IDS.cold_blood
IDS.debuff_rupture      = IDS.rupture
IDS.debuff_garrote      = IDS.garrote
IDS.debuff_expose_armor = IDS.expose_armor

-- ---------------------------------------------------------------------------
-- Poisons (apply spells, per rank) -- weapon coats applied out of combat
-- ---------------------------------------------------------------------------
IDS.poison_instant = { 8679, 8689, 8690, 8691, 11341, 11342, 11340 }  -- up to Instant Poison VI
IDS.poison_deadly  = { 2823, 2824, 11355, 11356, 25347, 434313 }       -- 434313 = SoD variant (VERIFY)
IDS.poison_wound   = { 13220, 13228, 13229, 13230 }
IDS.poison_occult  = { 458820, 1214170 }                               -- SoD Occult I/II
IDS.poison_sebacious = { 439500 }                                      -- SoD: armor shred (EA seed)
IDS.poison_numbing   = { 439505 }                                      -- SoD: melee slow

-- ---------------------------------------------------------------------------
-- Consumable item IDs
-- ---------------------------------------------------------------------------
IDS.item_thistle_tea          = 7676    -- +100 energy (rogue only)
IDS.item_major_healing_potion = 13446
IDS.item_free_action_potion   = 5634
IDS.item_elixir_mongoose      = 13452   -- +25 Agi / +2% crit
IDS.item_elixir_greater_agi   = 9187
IDS.item_juju_might           = 12460   -- +40 AP
IDS.item_juju_power           = 12451   -- +30 Str
IDS.item_winterfall_firewater = 12820   -- +35 AP
IDS.item_scorpok_assay        = 8412    -- +25 Agi
IDS.item_desert_dumplings     = 20452   -- +20 Str food
IDS.item_sharpening_elemental = 18262   -- +2% crit weapon
IDS.item_sharpening_dense     = 12404
IDS.item_flask_nightmares     = 221024  -- SoD physical flask (VERIFY stats)
IDS.item_goblin_sapper        = 10646   -- Goblin Sapper Charge (engineering burst)

-- Health potions list (best -> worst) for emergency self-heal
IDS.health_potions = { 13446, 3928, 1710, 929, 858, 118 }

return IDS
