
-- Example:
-- ---@type combat_forecast
-- local x = require("common/modules/combat_forecast")
-- x: -> IntelliSense
-- Warning: Access with ":", not "."

---@class forecast_lengths
---@field DISABLED number
---@field VERY_SHORT number
---@field SHORT number
---@field MEDIUM number
---@field LONG number

---@class combat_forecast
--- Enum for forecast modes.
---@field enum forecast_lengths
--- Gets the forecast data.
---@field get_forecast fun(self: nil): any
--- Forecasted seconds until this unit dies, clamped to 1..60 before the menu multipliers.
--- SPECIAL VALUES, on purpose: 1.1 = NO DATA (the unit is not tracked yet: not in combat, never
--- damaged, or the local player), short so min combat length checks refuse cooldowns on idle mobs;
--- 61.22 = training dummy, or a player when include_pvp is not true. Use has_forecast_data(unit) to
--- tell "no data" apart from a real 1.1 s estimate.
---@field get_forecast_single fun(self: nil, unit: game_object, include_pvp?: boolean): number
--- Returns true when the forecast tracks this unit (in combat, with damage data), i.e. when
--- get_forecast_single answers a real estimate instead of the 1.1 "no data" value. Added 2026-10-12.
---@field has_forecast_data fun(self: nil, unit: game_object): boolean
--- Gets the minimum combat length for a given forecast mode, plugin, and spell.
---@field get_min_combat_length fun(self: nil, forecast_mode: any, plugin_name: string, spell_name: string): number
--- Validates the forecast logic based on the minimum combat length and unit.
---@field is_valid_forecast_logic fun(self: nil, min_combat_length: number, unit?: game_object, include_pvp?: boolean): boolean

---@type combat_forecast
local tbl
return tbl
