-- =============================================================================
-- SoD Rogue Backstab/Cutthroat — entry point
-- =============================================================================
-- Loaded by the host. Wires the rotation into the engine's per-frame callbacks.
--
-- NOTE ON require() PATHS: this assumes the scripts root resolves these modules
-- as "rotations/sod_rogue_backstab/<name>" (same root that resolves
-- "common/izi_sdk"). If your loader roots elsewhere, adjust the prefix in this
-- file and in rotation.lua's requires.
-- =============================================================================

local rotation = require("rotations/sod_rogue_backstab/rotation")

core.register_on_update_callback(rotation.on_update)
core.register_on_render_menu_callback(rotation.on_render_menu)

if core and core.log then
    core.log("[sod_rogue_bs] loaded - SoD Rogue Backstab/Cutthroat rotation")
end
