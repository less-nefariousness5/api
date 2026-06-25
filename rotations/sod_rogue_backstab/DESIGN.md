# SoD Rogue — Backstab / Cutthroat Rotation: Design & Research Brief

**Target:** Season of Discovery (Classic) Rogue, Backstab build.
**Primary scope (this iteration):** Leveling 1–60, scaling into the level‑60 Cutthroat Backstab endgame loop.
**Positional handling:** Lean on the **Cutthroat** rune to remove Backstab's "must be behind" requirement; fall back to a frontal builder when Cutthroat is unavailable (early levels).
**Framework:** the `izi` SDK in this repo (`common/izi_sdk`), driven from `core.register_on_update_callback`.

> Sourcing note: live guide pages (Wowhead/Icy Veins/Warcraft Tavern/ComfyWizard) are egress‑blocked in the build environment, so rotation logic was taken from the **wowsims/SoD simulator APL preset files** (the community's canonical machine‑readable rotation) and IDs were verified against `wowhead.com/classic` URLs surfaced via search. Items flagged **VERIFY** below must be confirmed in‑game before they are hardcoded.

---

## 1. How rotations are built on this API

This repo is a LuaLS `---@meta` **type-definition package** — pure API surface, no runnable code and no existing rotation to copy. We build from scratch on the `izi` SDK, which is by far the most complete layer and the only one with documented usage examples and a per‑frame entry hook.

**Lifecycle / entry points** (`api/core.lua`):
- `core.register_on_update_callback(fn)` — main per‑frame combat tick (run the rotation here).
- `core.register_on_render_callback(fn)` — world drawing.
- `core.register_on_render_menu_callback(fn)` — settings UI.
- `core.register_on_render_control_panel_callback(fn)` — quick‑toggle bar.
- Inside our `on_update`, call `izi.on_update()` **once** to drive the SDK each frame (`izi_sdk.lua:526`).

**Core izi primitives we rely on** (all confirmed in `common/izi_sdk.lua`):

| Need | API | Notes |
|---|---|---|
| Player / target | `izi.me()`, `izi.target()`, `izi.ts(1)` | `target()` = current target; `ts(i)` = target‑selector pick |
| Energy | `me:energy_current()`, `energy_predicted(off,max)`, `energy_time_to_x(n)`, `energy_deficit()` | Classic regen = **20 energy / 2s tick** (10/s avg) |
| Combo points | `me:combo_points_current()`, `combo_points_deficit()` | izi normalizes the Classic vs TBC combo‑point power index |
| Behind check | `me:is_behind(target)` / `is_behind_unit` | rear‑arc test for Backstab when Cutthroat is absent |
| Spell needs back | `spell:requires_back()` | lets us detect Backstab's positional gate generically |
| Stealth | `me:stealth_up()`, `stealth_remains()` | opener gating |
| Buffs/debuffs | `unit:has_buff(spec)`, `buff_remains(spec)`, `has_debuff`, `debuff_remains` | `spec` may be an id or id‑array; remains in **seconds** |
| Spell object | `izi.spell(id1, id2, ...)` | **resolves to the highest known rank** — ideal for leveling |
| Cast | `spell:cast_safe(target, "msg", opts)` | full safety checks; `opts` can `skip_facing`, `skip_range`, `skip_gcd`, immunity, etc. |
| Cast on best | `spell:cast_target_if(units, "max"/"min", filter, ...)` | for AoE/low‑HP execute |
| Item object | `izi.item(id)` → `:cooldown_up()`, `:in_inventory()`, `:use_self_safe(msg,opts)` | poisons, Thistle Tea, potions |
| Swing timer | `common/utility/auto_attack_helper` → `get_next_attack_core_time(unit)` minus `core.time()` | time‑until‑next‑swing for energy/poison alignment |
| Cooldowns/CDs | `spell:cooldown_up()`, `cooldown_remains()`, `charges()` | AR/Blade Flurry/Cold Blood/Vanish |
| Menu | `common/ow_menu_api` → `new_checkbox/new_slider/new_keybind` | created once at load, rendered in the menu callback |
| TTD / combat | `target:time_to_die()`, `me:time_in_combat()`, `me:affecting_combat()` | end‑of‑fight CP dumps, prepull gating |

**`izi.spell(id1, id2, …)` is the linchpin for a leveling rotation:** pass *every rank ID* of an ability and the SDK auto‑selects the rank the character has actually learned. This means the rotation file works from level 1 upward without per‑level edits.

---

## 2. The build (what we're optimizing)

### Defining runes
| Rune | Slot | Effect | Role in rotation |
|---|---|---|---|
| **Slaughter from the Shadows** | Chest | −energy cost & +damage on Backstab/Ambush | Makes Backstab‑spam energy‑sustainable. **The keystone.** |
| **Cutthroat** | Hands/Gloves | Removes the *behind* requirement on Backstab/Ambush/Garrote; **Backstab has 15% chance to proc a free, no‑stealth Ambush** (10s window) | Removes positioning need; adds a free hard‑hitting builder |
| **Cut to the Chase** | (rune) | Eviscerate/Envenom **refreshes Slice and Dice to full 5‑CP duration** | If equipped, SnD is auto‑maintained — skip manual SnD recasts |
| **Carnage** | Bracers | +20% damage to targets affected by your Bleed (Rupture/Garrote) | Reason to keep Rupture up; **not** a positional bypass |
| **Master of Subtlety** | Boots | Damage buff aura, refreshed via Vanish/stealth | Burst‑window gating |
| **Quick Draw / Between the Eyes / Saber Slash / Blade Dance** | various | Alternate/competing builds | Not used by Backstab loop; menu‑optional later |

> **Chest‑slot conflict (important):** Slaughter from the Shadows and Deadly Brew **share the Chest slot**. The Backstab build runs Slaughter, so it **cannot** use Deadly Brew. That's why Backstab is the situational/poison‑immune‑boss pick at endgame while Mutilate/Saber Slash lead most fights.

### Positional handling (per your decision)
From the wowsims source (`backstab.go`): Backstab is castable when `hasCutthroatRune || !InFrontOfTarget`. So:
- **Cutthroat present** → Backstab fires from anywhere; no movement logic needed.
- **Cutthroat absent (early leveling)** → cast Backstab only when `me:is_behind(target)` is true; otherwise use the frontal builder (**Sinister Strike**, or **Saber Slash** if that rune is taken).

The rotation will detect this generically via `backstab:requires_back()` + `me:is_behind(target)` so it self‑adapts as the rune is unlocked.

### Talents (endgame target; leveling fills toward it)
Deep‑Subtlety hybrid, roughly **~3 Assassination / ~6 Combat / ~31 Subtlety**:
- **Subtlety core:** Opportunity 5/5 (+~20% Backstab), Improved Backstab 3/3 (+30% crit), Sinister Calling 5/5, Serrated Blades, Ghostly Strike, Initiative, then deep **Deadliness** (+10% AP) and **Preparation**.
- **Assassination:** **Relentless Strikes** (energy on finishers — the energy engine), Malice 5/5, Lethality, Improved Slice and Dice.
- **Combat:** **Precision** (melee hit; main flex slot, swap to Improved Expose Armor if the group needs EA), Dagger Specialization.

### Poisons & weapon imbues
- Standard: **Instant Poison** on the slow main‑hand (PPM benefits from slow speed; carries onto Backstab specials), a stacking/fixed‑per‑hit poison on the fast off‑hand.
- SoD off‑hand options: **Occult Poison** (Deadly‑like + stacking +2%/app magic damage‑taken, max +10%), **Sebacious Poison** (seeds Expose Armor via armor shred), **Wound Poison** (PvP healing reduction).
- The rotation should **re‑apply poisons when the weapon enchant is missing/expired** (via `game_object:item_enchant_id()/item_enchant_expiration()`), out of combat.

### Consumables (heavy in SoD — rotation can auto‑use)
Thistle Tea (+100 energy, rogue‑only, key burst/anti‑starvation), Elixir of the Mongoose (+25 Agi/+2% crit), Winterfall Firewater / Juju Might (AP), Grilled Squid / Smoked Desert Dumplings (food), Elemental Sharpening Stone (+2% crit MH), Flask of Everlasting Nightmares (SoD physical flask, **VERIFY stats**), Major Healing Potion, Free Action Potion, Goblin Sapper Charge (engineering burst).

### Stat priority
**Agility → Hit (to cap) → Crit → AP → Strength**, haste situational. Yellow (special) hit cap = **9%** vs a +3 boss; **Dagger Specialization (+5 weapon skill) + Precision** can cut required gear hit to ~1%. No crit suppression at level 60; white‑crit soft cap ~29.8% but **Backstab (yellow) crit is uncapped** → stack crit.

---

## 3. Verified IDs

> **Rank caveat:** core abilities have a **different spell ID per rank**. The implementation will pass full rank lists into `izi.spell(...)` so the SDK picks the learned rank. IDs below are base/known ranks unless noted; every per‑rank list must be **VERIFY**‑confirmed during implementation.

### Core abilities
| Ability | Base ID | Notes |
|---|---|---|
| Backstab | 53 | ranks differ; L60 ≈ 11281/25300 — pass full rank list |
| Sinister Strike | 1752 | frontal builder fallback |
| Slice and Dice | 6774 | buff aura = same id |
| Eviscerate | 2098 | primary finisher |
| Rupture | 1943 | bleed; debuff = same id |
| Ambush | 8676 | used on Cutthroat proc / from stealth |
| Garrote | 703 | opener bleed |
| Expose Armor | 11198 | EA variant |
| Gouge / Kick | 1776 / 1766 | interrupts/utility |
| Kidney Shot | 408 | stun finisher |
| Cheap Shot | 1833 | stealth opener |
| Slice & Dice | 6774 | (uptime) |
| Stealth | 1784 / 1786 | two ranks |
| Vanish | 1856 | MoS refresh / stealth Ambush |
| Sprint | 11305 | |
| Evasion | 5277 | defensive |
| Blind | 2094 | |
| Adrenaline Rush | 13750 | CD |
| Blade Flurry | 13877 | CD / cleave |
| Cold Blood | 14177 | pair with Eviscerate |
| Preparation | 14185 | CD reset |
| Premeditation | 14183 | +2 CP opener |
| Ghostly Strike | 14278 | filler |

### SoD rune abilities/auras (HIGH confidence)
| Name | Spell ID | Rune item / slot |
|---|---|---|
| Cutthroat (proc aura) | **462707** (proc), rune cast 424980 | Gloves |
| Slaughter from the Shadows | (rune) | Chest |
| Cut to the Chase | 432271 | rune |
| Carnage | 432276 | item 221461, Bracers |
| Master of Subtlety | 425096 | Boots |
| Shadowstrike | 399985 | item 204795, Gloves |
| Saber Slash | 424785 | item 208772, Gloves |
| Blade Dance | 400012 | item 208771, Legs |
| Envenom (rune) | 399963 | Legs |
| Deadly Brew | 399965 | item 203994, Chest (conflicts with Slaughter) |
| Between the Eyes | 400009 | Legs |
| Quick Draw | 398196 | item 203991, Chest |
| Shadowstep | 400029 | item 210979, Belt |

### Poisons (apply spell — per rank)
| Poison | Apply ID | Notes |
|---|---|---|
| Instant Poison VI (L60) | 11340 | lower ranks I=8679, IV=11341, V=11342 |
| Deadly Poison V (L60) | 25347 | SoD variant 434313 (**VERIFY**) |
| Wound Poison IV | 13230 | I=13220 |
| Occult Poison I / II (SoD) | 458820 / 1214170 | (suggested 439501 was **wrong**) |
| Sebacious Poison (SoD) | 439500 | −1700 armor (EA seeding) |
| Numbing Poison (SoD) | 439505 | melee slow |

### Consumable items
| Item | ID |
|---|---|
| Thistle Tea | 7676 |
| Major Healing Potion | 13446 |
| Free Action Potion | 5634 |
| Elixir of the Mongoose | 13452 |
| Elixir of Greater Agility | 9187 |
| Juju Might / Juju Power | 12460 / 12451 |
| Winterfall Firewater | 12820 |
| Ground Scorpok Assay | 8412 |
| Smoked Desert Dumplings | 20452 |
| Elemental / Dense Sharpening Stone | 18262 / 12404 |
| Flask of Everlasting Nightmares | 221024 (**VERIFY stats**) |

---

## 4. Rotation logic (leveling‑adaptive)

Transcribed/de‑jargoned from the wowsims `Slaughter_Cutthroat_60` APL and `P6_Backstab` APL, then made level‑aware. Energy regen is slow (10/s), so the governing rule is **"build to 5 CP, dump a finisher, never overcap energy, never let Slice and Dice drop."**

```
on_update():
  izi.on_update()
  me, target = izi.me(), izi.target() (or ts(1))
  guard: enabled, me alive & in combat-able, target valid enemy, in melee range

  --- OUT OF COMBAT / PREP ---
  if not in combat:
    (optional) re-apply poisons if weapon enchant missing
    (optional) open from Stealth: Premeditation -> Cheap Shot/Ambush/Garrote -> seed CP
    return

  cp     = me:combo_points_current()
  energy = me:energy_current()

  --- COOLDOWNS (only when not stealthed) ---
  if not stealthed and burst enabled:
    Thistle Tea if energy very low (<=15) and cp<5
    Adrenaline Rush / Blade Flurry on cooldown
    if Cold Blood ready and cp>=4: Cold Blood -> (next) Eviscerate   # guaranteed crit

  --- FREE PROC AMBUSH ---
  if Cutthroat proc (462707) up: cast Ambush; return

  --- FINISHERS (priority order) ---
  # Slice and Dice has top priority for first application & uptime
  if cp>=1 and SnD down (and NOT running Cut-to-the-Chase): SnD; return
  # Rupture for bleed + Carnage synergy (skip while very low level / no rune value)
  if cp>=4 and Rupture missing/expiring(<2s) and target TTD>~8s: Rupture; return
  # Eviscerate dump
  if cp>=5: Eviscerate; return
  if cp>=4 and (energy>=energy_max-20 or target TTD<=4): Eviscerate; return
  if target TTD<=3 and cp>=2: Eviscerate; return   # end-of-fight dump

  --- BUILDER ---
  if cp<5 and energy >= builder_cost:
    if backstab usable (Cutthroat present OR me:is_behind(target)):
        Backstab
    else:
        Sinister Strike   # frontal fallback (or Saber Slash if that rune)
```

**Leveling adaptations baked in:**
- `izi.spell(rank_list)` auto‑selects learned rank → no per‑level edits.
- Rupture/finisher‑heavy logic is value‑gated on TTD so it doesn't waste GCDs on fast‑dying low‑level mobs.
- Positional fallback to Sinister Strike covers the pre‑Cutthroat window.
- Defensive auto‑use (Evasion, Major Healing Potion at low HP) for solo survivability while questing.
- AoE branch (optional, menu‑gated): at 2+ enemies in splash range Blade Flurry fires as the cleave button (independent of the burst key); at `aoe_threshold`+ enemies the finisher swaps to **Crimson Tempest** (SoD AoE bleed rune) and the builder switches to the frontal strike (Saber Slash / Sinister Strike — cleaves through Blade Flurry, no positional requirement). Rupture is suppressed in AoE.

**Tank mode (menu‑gated — Just a Flesh Wound / Blade Dance build):**
Damage = threat, so the normal priority still drives most of it; tank mode layers threat tools on top and disables threat‑shedding behaviour. **All SoD tank‑rune IDs are VERIFY** (the SoD tank guide was egress‑blocked) and auto‑filter from `izi.spell` if wrong, so they no‑op rather than miscast.
- *Blade Dance* upkeep (parry + threat; no‑ops if the rune is passive), *Main Gauche* off‑hand threat strike on cooldown, and *Feint* as a threat filler under Just a Flesh Wound (energy‑buffered so it never starves a builder/finisher).
- Vanish burst, auto‑stealth and stealth openers are all suppressed (they shed threat).
- Evasion is rolled proactively while tanking 2+ enemies, on top of the HP‑gated defensive use.

**Extra spell/rune logic (menu‑gated):**
- *Vanish burst* — in the burst window Vanish is used as a damage cooldown; next frame we are stealthed and the opener fires an instant Ambush, and it refreshes the **Master of Subtlety** aura. Sheds threat/combat, so opt‑in (default off).
- *Preparation* — resets Vanish/Cold Blood once Vanish is on cooldown, for a second burst.
- *Goblin Sapper Charge* — AoE/burst nuke at 2+ targets (self‑damaging, opt‑in).
- *Gouge interrupt‑fallback* — interrupts when Kick is on cooldown / the target is Kick‑immune.
- *Expose Armor* — opt‑in single‑target armor‑debuff maintenance (full 5‑CP application; pairs with Sebacious Poison seeding); suppressed in AoE.
- *Free Action Potion* — used when `me:is_rooted()`/`is_stunned()` in combat, to keep attacking.

**Automation layer (menu‑gated, runs around the combat list):**
- *Ensure auto‑attack* — on a fresh/swapped target, if `me:is_auto_attacking()` is false we call `auto_attack_helper:start_attack(target, MELEE)` so white swings always start.
- *Auto‑stealth* — out of combat with an enemy inside `stealth_range`, cast Stealth to approach for a free opener.
- *Auto‑loot* — out of combat, `loot_object()` the nearest corpse returned by `get_enemies_in_range_if(loot_range, …, is_lootable)`.
- *Target cleanup* — once the current target is dead (and looted, if auto‑loot owns it) swap to the next live enemy via `set_target`, or clear the selection so the selector re‑acquires. (Clearing via `set_target(nil)` is **VERIFY** — wrapped in pcall.)

---

## 5. Swing timer / energy notes

- **Energy:** 20 per 2s tick. Pool only enough to chain builder+finisher; the real gate is "don't overcap" (≈ max−20). `energy_predicted()`/`energy_time_to_x()` let us avoid clipping a tick.
- **Backstab weapon:** slow (1.8) main‑hand preferred (Backstab scales off MH listed damage), fast off‑hand for poison procs. The rotation doesn't pick weapons but should not assume haste.
- **Swing alignment** (`auto_attack_helper:get_next_attack_core_time`) is a *marginal* gain for daggers — low priority; we expose it but won't over‑engineer it initially.

---

## 6. Proposed implementation architecture

```
rotations/sod_rogue_backstab/
  DESIGN.md            <- this file
  ids.lua              <- all spell/rune/item id tables (rank lists), single source of truth
  menu.lua             <- ow_menu_api elements (enable, burst key, AoE, consumable toggles, sliders)
  rotation.lua         <- the on_update priority list; requires ids + menu + izi
  main.lua             <- entry: requires modules, registers core callbacks
```

- **One source of truth for IDs** (`ids.lua`) so VERIFY fixes happen in one place.
- **Menu‑gated behaviors:** master enable, single‑target/AoE, auto‑cooldowns, auto‑consumables, auto‑poison, defensive thresholds, finisher CP threshold, energy‑pool slider.
- **Self‑adapting** to learned ranks and equipped runes so the same file serves levels 1→60.

---

## 7. Open verification TODOs (before shipping)
1. Confirm **per‑rank IDs** for Backstab/SS/Eviscerate/Rupture/SnD/Ambush/etc. (build full rank lists).
2. Confirm the **Cutthroat proc aura id 462707** is what the live client shows; confirm **Master of Subtlety** triggered‑buff id vs rune id 425096.
3. Confirm **Slaughter from the Shadows** spell/aura id and energy‑cost values (used only for tuning, not casting).
4. Confirm **Flask of Everlasting Nightmares** stats and current‑phase consumable values.
5. Confirm how the loader exposes `require` paths so module files resolve `common/izi_sdk` correctly, and where rotation files must live on disk.
```
