
-- Example:
-- ---@type spell_helper
-- local x = require("common/utility/spell_helper")
-- x: -> IntelliSense
-- Warning: Access with ":", not "."

---@class spell_helper
--- Check if the spell is in the spellbook.
--- VERSIONS: needs core.spell_book.has_spell to answer true once before it trusts it. Until then
--- (on a client where has_spell never works, e.g. the TBC 2.5.3 private server) it answers
--- from is_spell_learned alone.
---@field has_spell_equipped fun(self: spell_helper, spell_id: number): boolean

---@class spell_helper
--- Check if the spell is currently on cooldown.
---@field is_spell_on_cooldown fun(self: spell_helper, spell_id: number, skip_usable: boolean?, skip_controller: boolean?): boolean

---@class spell_helper
--- Check if a spell is within castable range given a target.
--- VERSIONS: branches on core.get_game_version(). Its own melee-reach math is 4 yd + radius
--- (x0.99) on Retail and 3 yd + radius (x0.966) on every other build. On "Vanilla" (Classic Era
--- and the Vanilla 1.14 private server) a ranged auto attack counts as out of range while you move.
---@field is_spell_in_range fun(self: spell_helper, spell_id: number, target: game_object, source: vec3, destination: vec3): boolean

---@class spell_helper
--- Check if the target is within a permissible angle for casting a spell.
---@field is_spell_within_angle fun(self: spell_helper, spell_id: number, caster: game_object, target: game_object, caster_position: vec3, target_position: vec3): boolean

---@class spell_helper
--- Check if the caster has the target in line of sight.
---@field is_spell_in_line_of_sight fun(self: spell_helper, spell_id: number, caster: game_object, target: game_object): boolean

---@class spell_helper
--- Check if the caster has the target in line of sight.
---@field is_spell_in_line_of_sight_position fun(self: spell_helper, spell_id: number, caster: game_object, cast_position: vec3): boolean

---@class spell_helper
--- Retrieve the cost of a spell.
---@field get_spell_cost fun(self: spell_helper, spell_id: number): table

---@class spell_helper
--- Check if a unit has enough resources to cast a spell.
--- VERSIONS: always true on the private-server clients (Vanilla 1.14 / TBC 2.5.3); the cost is
--- not checked there.
---@field can_afford_spell fun(self: spell_helper, unit: game_object, spell_id: number, spell_costs: table): boolean

---@class spell_helper
--- Check if the spell can be cast by considering various factors like cooldown, range, and caster's resources.
---@field is_spell_castable fun(self: spell_helper, spell_id: number, caster: game_object, target: game_object, skip_facing: boolean, skips_range: boolean, skip_usable: boolean?, skip_controller: boolean?, skip_learned: boolean?, skip_los: boolean?): boolean

---@class spell_helper
--- Check if the spell can be cast (on position vec3) by considering various factors like cooldown, range, and caster's resources.
---@field is_spell_castable_position fun(self: spell_helper, spell_id: number, caster: game_object, target: game_object, cast_position: vec3, skip_facing: boolean, skips_range: boolean,  is_queue: boolean?, skip_usable: boolean?, skip_controller: boolean?, skip_learned: boolean?, skip_los: boolean?): boolean

---@class spell_helper
--- Check if the spell can be cast by considering various factors like cooldown, range, and caster's resources.
---@field is_spell_queueable fun(self: spell_helper, spell_id: number, caster: game_object, target: game_object, skip_facing: boolean, skips_range: boolean, skip_usable: boolean?, skip_controller: boolean?, skip_learned: boolean?, skip_los: boolean?): boolean

---@class spell_helper
--- Return parsed tooltip info, is not precise and doesnt support all spells.
---@field get_spell_damage fun(self: spell_helper, spell_id: number, ignore_percentage?: boolean, ignore_flat: boolean?): number

---@class spell_helper
--- Return parsed tooltip info, is not precise and doesnt support all spells.
---@field get_spell_healing fun(self: spell_helper, spell_id: number, ignore_percentage?: boolean, ignore_flat: boolean?): number

---@class spell_helper
--- Return the cooldown remaining of current charge and the total cooldown for all the remaining charges
---@field get_remaining_charge_cooldown fun(self: spell_helper, spell_id: number): number, number

---@type spell_helper
local tbl
return tbl
