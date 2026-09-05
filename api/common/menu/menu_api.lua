---@diagnostic disable: duplicate-doc-field, missing-return
---@meta

---@alias color_helper color

-- =============================================================================
-- LEGACY MENU API (`require("common/menu/menu_api")`) — LuaLS stub.
--
-- This is the OW/League-style imperative menu surface. In the wow tree it is a
-- COMPATIBILITY SHIM: the old left/right-pane menu is retired, and every
-- element created here is a thin proxy that declares a matching widget in the
-- NEW declarative menu (`_G.menu`, see .api/common/menu/api.lua). Prefer
-- `_G.menu` for new work; use this only for code shared with the older menus.
--
-- How legacy trees map onto the new sidebar/content layout:
--     top-level tree              → sidebar PAGE
--     depth-1 subtree             → SECTION card on that page
--     depth-2 subtree             → SUBSECTION inside the section
--     depth-3+ subtree            → nested subsection (collapsed by default)
--     elements outside any tree   → an implicit "Options" section
--
-- Conditional rendering is preserved: only elements :render()'d this frame are
-- visible, but every element stays registered so persistence and keybind
-- ticking keep working while hidden.
--
-- The legacy per-element STYLING options (window_checkbox_options etc.) are
-- accepted for source compatibility but IGNORED by the new menu — widgets are
-- themed centrally. Only the fields explicitly marked "live" below still work.
-- =============================================================================
--
-- COMPLETE COMPATIBILITY EXAMPLE
-- ------------------------------
--   local legacy = require("common/menu/menu_api")
--   local root = legacy.new_tree("my_plugin_root", { icon = "widgets" })
--   local enabled = legacy.new_checkbox("my_plugin_enabled", true)
--   local activation = legacy.new_keybind(true, false, 0x54,
--       "my_plugin_activation", {
--           modes = { "toggle", "hold" },
--           description = "Enable the feature while this bind is active",
--       })
--
--   core.register_on_render_menu_callback(function()
--       root:render("My Plugin", function()
--           enabled:render("Enabled")
--           activation:render("Activation")
--       end)
--   end)
--
--   if enabled:get() and activation:get_state() then
--       -- feature logic
--   end
--
-- Construct proxies once and render the same instances from the callback.
-- Prefix every id with the plugin name: id is persistence identity, while the
-- render label can be translated or renamed safely. Constructor defaults are
-- the first-run and reset defaults.
--
-- LEGACY KEYBIND TIPS
-- -------------------
-- `is_toggle` selects the default mode (true = toggle, false = hold). Omit
-- opts.modes to lock it, or list exactly the choices the user may cycle:
--
--   { modes = { "toggle", "hold" } } -- flexible, never offers release
--
-- Click the key pill and press a key to rebind. Double-click the mode badge
-- within 0.40 seconds to cycle its declared modes. A failed single click shows
-- help once per session after that timeout; "Don't remind me again" persists at
-- scripts_data/menu/keybind_mode_hint.txt. The compatibility constructor cannot
-- declare WoW modifier chords. Use `_G.menu` + `default_mods` for new chorded
-- binds; this is one reason the declarative API is recommended for new work.
-- =============================================================================

-- =============================================================================
-- OPTION TYPES (legacy styling — ignored by the new menu unless marked live)
-- =============================================================================

---@class window_checkbox_options
---@field on_changed? fun(state: boolean) IGNORED in the wow shim — poll :get() or use _G.menu's on_change
---@field text_color? color_helper IGNORED (themed centrally)
---@field box_background? color_helper IGNORED
---@field box_border? color_helper IGNORED
---@field box_rounding? number IGNORED
---@field animation_speed? number IGNORED

---@class window_slider_options
---@field suffix? string LIVE: unit text after the value readout (e.g. "%")
---@field fill_color? color_helper IGNORED (themed centrally)
---@field outline_color? color_helper IGNORED
---@field label_color? color_helper IGNORED
---@field value_color? color_helper IGNORED
---@field animation_speed? number IGNORED

---@class window_button_options
---@field on_click? fun() LIVE: fired when the button is clicked
---@field description? string LIVE: hover tooltip
---@field style? "default"|"primary"|"danger"|"ghost" LIVE: visual style
---@field icon? string LIVE: icon catalog key (common/menu/icons.lua)
---@field fill_color? color_helper IGNORED (themed centrally)
---@field text_color? color_helper IGNORED
---@field border_radius? number IGNORED
---@field pulse_color? color_helper IGNORED
---@field animation_speed? number IGNORED

---@class window_keybind_options
---@field modes? ("hold"|"toggle"|"release")[] LIVE: exact user-selectable modes in double-click cycle order; omit or give one valid entry to lock; release is opt-in
---@field confirm_rebind? boolean Require explicit confirmation, then a second click, before key capture
---@field description? string LIVE: hover tooltip fallback
---@field fill_color? color_helper IGNORED (themed centrally)
---@field outline_color? color_helper IGNORED
---@field label_color? color_helper IGNORED
---@field animation_speed? number IGNORED

---@class menu_tree_options
---@field icon? string LIVE (top-level trees): sidebar icon catalog key (common/menu/icons.lua M.map)
---@field ns? string LIVE: plugin namespace used for icon inference when no icon is given
---@field column? "left"|"right"|"full" LIVE (depth-1 trees): section layout slot (default "full")

---@class window_key_checkbox_options
---@field border_color? color_helper IGNORED

---@class window_text_input_options
---@field default? string LIVE: initial text
---@field placeholder? string LIVE: ghost text while empty
---@field max_len? integer LIVE: max characters
---@field font_id? integer IGNORED (themed centrally)
---@field numeric_only? boolean IGNORED
---@field multiline? boolean IGNORED
---@field on_change? fun(text: string) IGNORED — poll :get_text()

-- =============================================================================
-- MENU ELEMENT INSTANCES (proxies onto the new menu)
-- =============================================================================

---@class menu_tree_node
---Renders the tree node and executes `callback` inside it. Depth decides what
---it becomes: page (top level), section (depth 1), subsection (deeper).
---@field render fun(self: menu_tree_node, header: string, callback?: fun()): nil
---Legacy alias of render (the window argument is ignored).
---@field render_to_window fun(self: menu_tree_node, window: window, header: string, callback?: fun()): nil
---Always true in the shim (pages/sections manage their own collapse state).
---@field is_open fun(self: menu_tree_node): boolean
---No-op chain helper kept for source compatibility. Returns self.
---@field attach_texture fun(self: menu_tree_node, ...): menu_tree_node
---@field get_attached_texture_info fun(self: menu_tree_node): nil
---@field attach fun(self: menu_tree_node): nil
---@field set_expanded fun(self: menu_tree_node, ...): nil

---@class menu_checkbox
---Renders the checkbox with a label and optional hover tooltip
---@field render fun(self: menu_checkbox, label: string, tooltip?: string): nil
---@field render_to_window fun(self: menu_checkbox, window: window, label: string, tooltip?: string): nil
---Returns the current checked state
---@field get fun(self: menu_checkbox): boolean
---Sets the checked state
---@field set fun(self: menu_checkbox, state: boolean): nil
---Always false in the shim (hover isn't tracked per element)
---@field is_hovered fun(self: menu_checkbox): boolean
---Always false in the shim
---@field is_clicked fun(self: menu_checkbox): boolean

---@class menu_slider
---Renders the slider. `step` snaps the drag value to multiples of step.
---@field render fun(self: menu_slider, label: string, step?: number, tooltip?: string): nil
---@field render_to_window fun(self: menu_slider, window: window, label: string, step?: number, tooltip?: string): nil
---Returns the current value (rounded when in integer mode)
---@field get fun(self: menu_slider): number
---@field set fun(self: menu_slider, value: number): nil
---Switch to float mode. Returns self for chaining.
---@field as_float fun(self: menu_slider): menu_slider
---Switch to integer mode. Returns self for chaining.
---@field as_int fun(self: menu_slider): menu_slider
---Always false in the shim
---@field is_hovered fun(self: menu_slider): boolean

---@class menu_button
---Renders the button. Returns true on the frame it was clicked, so both
---`if btn:render("Go") then ... end` and `btn:render("Go"); if btn:is_clicked() then ... end` work.
---@field render fun(self: menu_button, label: string, tooltip?: string): boolean
---@field render_to_window fun(self: menu_button, window: window, label: string, tooltip?: string): boolean
---True on the frame the button was clicked (latched across the same frame's render)
---@field is_clicked fun(self: menu_button): boolean
---Replace the click callback
---@field set_on_click fun(self: menu_button, cb: fun()): nil
---@field get_bounds fun(self: menu_button): nil
---@field is_hovered fun(self: menu_button): boolean

---@class menu_keybind
---Renders the keybind selector
---@field render fun(self: menu_keybind, label: string, tooltip?: string): nil
---@field render_to_window fun(self: menu_keybind, window: window, label: string, tooltip?: string): nil
---Returns the currently bound key code
---@field get_key_code fun(self: menu_keybind): integer
---Sets the bound key code
---@field set_key fun(self: menu_keybind, keycode: integer): nil
---True while the bind is on: held (hold) or latched (toggle flips on key press;
---release flips on key RELEASE — pressing does nothing until the key is lifted).
---@field get_state fun(self: menu_keybind): boolean
---Alias of get_state
---@field is_active fun(self: menu_keybind): boolean
---True when the bind is in toggle mode
---@field get_toggle_state fun(self: menu_keybind): boolean
---Switch between toggle (true) and hold (false)
---@field set_toggle_state fun(self: menu_keybind, state: boolean): nil
---Alias of set_toggle_state
---@field set_is_toggle fun(self: menu_keybind, state: boolean): nil
---Trigger mode: "hold" | "toggle" | "release" ("release" latches like toggle but flips on key-up)
---@field get_mode fun(self: menu_keybind): "hold"|"toggle"|"release"
---Force a trigger mode from code (unknown strings fall back to "hold")
---@field set_mode fun(self: menu_keybind, mode: "hold"|"toggle"|"release"): nil
---@field get_default_key fun(self: menu_keybind): integer
---@field get_label fun(self: menu_keybind): string
---@field get_bounds fun(self: menu_keybind): nil
---@field cancel_input_on_rect fun(self: menu_keybind, ...): nil
--- [WOW ONLY] Internal native-bridge hook: sets the displayed/runtime latch
--- without going through set_toggle_state, whose meaning on this proxy is the
--- trigger mode. Not a portable plugin API.
---@field _set_active fun(self: menu_keybind, active: boolean): nil

---@class menu_key_checkbox
---Renders the key checkbox (toggle-style keybind row)
---@field render fun(self: menu_key_checkbox, label: string, tooltip?: string): nil
---@field render_to_window fun(self: menu_key_checkbox, window: window, label: string, tooltip?: string): nil
---True while the toggle is latched on
---@field get_state fun(self: menu_key_checkbox): boolean
---Alias of get_state
---@field is_active fun(self: menu_key_checkbox): boolean
---@field get_key_code fun(self: menu_key_checkbox): integer
---@field set_key fun(self: menu_key_checkbox, keycode: integer): nil
---@field set_toggle_state fun(self: menu_key_checkbox, state: boolean): nil
---Declared "show on control panel/binds" default from construction
---@field is_shown_on_binds fun(self: menu_key_checkbox): boolean

---@class menu_dropdown
---Renders the dropdown; pass `options` to (re)set the item labels
-- [WOW ONLY] The third render argument preserves the native combobox tooltip.
---@field render fun(self: menu_dropdown, label: string, options?: string[], tooltip?: string): nil
---@field render_to_window fun(self: menu_dropdown, window: window, label: string, options?: string[], tooltip?: string): nil
-- [/WOW ONLY]
---Returns the currently selected index (1-based)
---@field get fun(self: menu_dropdown): integer
---@field set fun(self: menu_dropdown, index: integer): nil
---Alias of set
---@field select fun(self: menu_dropdown, index: integer): nil
---@field set_items fun(self: menu_dropdown, items: string[]): nil
---Returns the label of the selected item
---@field get_selected_item fun(self: menu_dropdown): string|nil
---@field get_item_count fun(self: menu_dropdown): integer
---Always false in the shim
---@field is_dropdown_open fun(self: menu_dropdown): boolean
---Change callback, fired from :render when the selection differs from last frame
---@field on_changed fun(self: menu_dropdown, callback: fun(new_index: integer)): nil
---@field remove_on_changed fun(self: menu_dropdown): nil
---@field toggle fun(self: menu_dropdown): nil
---@field open fun(self: menu_dropdown): nil
---@field close fun(self: menu_dropdown): nil

---@class menu_multi_dropdown
---Renders the multi-select dropdown; pass `items` to (re)set the options
---@field render fun(self: menu_multi_dropdown, label: string, items?: string[]): nil
---@field render_to_window fun(self: menu_multi_dropdown, window: window, label: string, items?: string[]): nil
---@field set_items fun(self: menu_multi_dropdown, items: string[]): nil
---@field get_items fun(self: menu_multi_dropdown): string[]
---Selected item indices (1-based)
---@field get_enabled_indices fun(self: menu_multi_dropdown): integer[]
---Selected item labels
---@field get_enabled_items fun(self: menu_multi_dropdown): string[]
---@field get_disabled_indices fun(self: menu_multi_dropdown): integer[]
---@field get_disabled_items fun(self: menu_multi_dropdown): string[]
---Select one option by index
---@field select fun(self: menu_multi_dropdown, index: integer): nil
---@field select_all fun(self: menu_multi_dropdown): nil
---@field clear_all fun(self: menu_multi_dropdown): nil
---First selected item's label, or nil
---@field get_selected_item fun(self: menu_multi_dropdown): string|nil
---@field get_item_count fun(self: menu_multi_dropdown): integer
---@field enable_search fun(self: menu_multi_dropdown): nil
---@field toggle fun(self: menu_multi_dropdown): nil
---@field open fun(self: menu_multi_dropdown): nil
---@field close fun(self: menu_multi_dropdown): nil

---@class menu_colorpicker
---Renders the color picker
---@field render fun(self: menu_colorpicker, label: string, tooltip?: string): nil
---@field render_to_window fun(self: menu_colorpicker, window: window, label: string, tooltip?: string): nil
---Returns the current color as a color_helper object
---@field get_color fun(self: menu_colorpicker): color_helper
---@field set_color fun(self: menu_colorpicker, c: color_helper): nil
---@field set_color_rgba fun(self: menu_colorpicker, r: integer, g: integer, b: integer, a?: integer): nil
---Alias of set_color
---@field set fun(self: menu_colorpicker, c: color_helper): nil
---@field toggle fun(self: menu_colorpicker): nil
---@field open fun(self: menu_colorpicker): nil
---@field close fun(self: menu_colorpicker): nil

---@class menu_dropdown_reorderable
---Renders the reorderable dropdown. Legacy (window, label) form also accepted.
---@field render fun(self: menu_dropdown_reorderable, label: string): nil
---@field set_items fun(self: menu_dropdown_reorderable, items: string[]): nil
---Item labels in the user's CURRENT order (highest priority first)
---@field get_items fun(self: menu_dropdown_reorderable): string[]
---@field set_handle_icon fun(self: menu_dropdown_reorderable, ...): nil
---@field toggle fun(self: menu_dropdown_reorderable): nil
---@field open fun(self: menu_dropdown_reorderable): nil
---@field close fun(self: menu_dropdown_reorderable): nil

---@class menu_text_input
---Renders the text input
-- [WOW ONLY] Legacy core.menu text inputs carry an optional tooltip.
---@field render fun(self: menu_text_input, label: string, tooltip?: string): nil
---@field render_to_window fun(self: menu_text_input, window: window, label: string, tooltip?: string): nil
-- [/WOW ONLY]
---@field get_text fun(self: menu_text_input): string
---@field set_text fun(self: menu_text_input, text: string): nil
---Alias of set_text
---@field set fun(self: menu_text_input, text: string): nil
---@field get_number fun(self: menu_text_input): number
---@field set_number fun(self: menu_text_input, value: number): nil
---Always false in the shim
---@field is_focused fun(self: menu_text_input): boolean
---@field focus fun(self: menu_text_input): nil
---@field blur fun(self: menu_text_input): nil

-- =============================================================================
-- BOUND MENU FACTORY (returned by menu_api.bind — the window arg is ignored
-- by the shim; constructors are identical to the module-level new_* ones)
-- =============================================================================

---@class menu_bound_factory
---@field window window The bound window (unused by the shim)
---@field checkbox fun(id: string, default_state?: boolean, opts?: window_checkbox_options): menu_checkbox
---@field slider fun(min_value: number, max_value: number, default_value: number, id: string, opts?: window_slider_options): menu_slider
---@field button fun(opts?: window_button_options): menu_button
---@field keybind fun(is_toggle: boolean, default_state: boolean, default_key_code: integer, id: string, opts?: window_keybind_options): menu_keybind
---@field dropdown fun(default_index: integer, items: string[], id: string): menu_dropdown
---@field tree fun(id: string, opts?: menu_tree_options): menu_tree_node
---@field key_checkbox fun(id: string, default_is_toggle: boolean, default_show_in_binds: boolean, default_toggle_state: boolean, default_key_code: integer, opts?: window_key_checkbox_options): menu_key_checkbox
---@field multi_dropdown fun(id: string, items?: string[], default?: integer[]|boolean[]): menu_multi_dropdown
---@field colorpicker fun(default_color: color_helper, id: string): menu_colorpicker
---@field dropdown_reorderable fun(id: string, items: string[]): menu_dropdown_reorderable
---@field text_input fun(id: string, opts?: window_text_input_options): menu_text_input

-- =============================================================================
-- MAIN MODULE
-- =============================================================================

---@class menu_api
---@field _NAME string Module name
---@field _VERSION string "2.0.0-compat"
---@field i18n menu_i18n Internationalization subsystem
---@field combobox table|nil Raw legacy element module (nil in the wow tree)
local menu_api = {}

---Creates a checkbox proxy
---@param id string Unique identifier for persistence
---@param default_state? boolean Initial checked state (default false)
---@param opts? window_checkbox_options Legacy styling — ignored
---@return menu_checkbox
function menu_api.new_checkbox(id, default_state, opts) end

---Creates a slider proxy (integer mode by default when the range is >= 2; see as_int/as_float)
---@param min_value number
---@param max_value number
---@param default_value number
---@param id string Unique identifier for persistence
---@param opts? window_slider_options opts.suffix is live; styling is ignored
---@return menu_slider
function menu_api.new_slider(min_value, max_value, default_value, id, opts) end

---Creates a button proxy
---@param opts? window_button_options on_click/description/style/icon are live
---@return menu_button
function menu_api.new_button(opts) end

---Creates a keybind proxy
---@param is_toggle boolean Toggle (true) or hold (false) default mode
---@param default_state boolean Default toggle state (toggle mode only)
---@param default_key_code integer Default virtual-key code (0 or 999 = unbound)
---@param id string Unique identifier for persistence
---@param opts? window_keybind_options modes/description are live; legacy styling is ignored. Use the modern API when `default_mods` is required.
---@return menu_keybind
function menu_api.new_keybind(is_toggle, default_state, default_key_code, id, opts) end

---Creates a key checkbox proxy (toggle-style keybind row)
---@param id string Unique identifier for persistence
---@param default_is_toggle boolean
---@param default_show_in_binds boolean
---@param default_toggle_state boolean
---@param default_key_code integer
---@param opts? window_key_checkbox_options Legacy styling — ignored
---@return menu_key_checkbox
function menu_api.new_key_checkbox(id, default_is_toggle, default_show_in_binds, default_toggle_state, default_key_code, opts) end

---Creates a dropdown proxy.
---Supports both `(default_index, items, id)` and the legacy `(default_index, id)`.
---@param default_index integer Default selected index (1-based)
---@param items string[] Option labels (may also be passed to :render / :set_items)
---@param id string Unique identifier for persistence
---@return menu_dropdown
---@overload fun(default_index: integer, id: string): menu_dropdown
function menu_api.new_dropdown(default_index, items, id) end

---Alias of new_dropdown (same overloads)
---@param default_index integer
---@param items string[]
---@param id string
---@return menu_dropdown
---@overload fun(default_index: integer, id: string): menu_dropdown
function menu_api.new_combobox(default_index, items, id) end

---Creates a multi-select dropdown proxy
---@param id string Unique identifier for persistence
---@param items? string[] Option labels
---@param default? integer[]|boolean[] Selected indices ({1,3}) or a literal boolean mask
---@return menu_multi_dropdown
function menu_api.new_multi_dropdown(id, items, default) end

---Creates a color picker proxy
---@param default_color color_helper Default color
---@param id string Unique identifier for persistence
---@return menu_colorpicker
function menu_api.new_colorpicker(default_color, id) end

---Creates a reorderable dropdown proxy (value = user-ordered items)
---@param id string Unique identifier for persistence
---@param items string[] Item labels
---@return menu_dropdown_reorderable
function menu_api.new_dropdown_reorderable(id, items) end

---Creates a text input proxy
---@param id string Unique identifier for persistence
---@param opts? window_text_input_options default/placeholder/max_len are live
---@return menu_text_input
function menu_api.new_text_input(id, opts) end

---Creates a tree node proxy. Nesting depth decides what it renders as:
---page (top level) → section (depth 1) → subsection (depth 2+).
---@param id string Unique identifier (page/section identity — keep it stable)
---@param opts? menu_tree_options icon/ns/column are live
---@return menu_tree_node
function menu_api.new_tree(id, opts) end

-- [WOW ONLY] Private entry points used by the legacy core.menu imperative-tree
-- adapter. They are not a portable plugin API.
---@param id string
---@param label string
---@param opts? menu_tree_options
---@return boolean
function menu_api.begin_imperative_tree(id, label, opts) end

---@return boolean
function menu_api.end_imperative_tree() end

---Private callback-isolation boundary used by the WoW bridge.
function menu_api.reset_callback_context() end

---Switches the staged menu build the bridge drives across frames.
---`discover` walks only top-level trees to populate the sidebar; `materialize`
---builds element bodies until `budget` build units are spent, then raises the
---init-yield sentinel; `ready` is the normal per-frame mode.
---@param mode "ready"|"discover"|"materialize"
---@param budget? number Build units allowed this frame in `materialize`.
function menu_api.set_build_mode(mode, budget) end

---True when `err` is the init-yield sentinel raised once a materialize pass
---exhausts its build budget. That is control flow, not a plugin error: the
---caller must re-raise it so the host retries the callback next frame.
---@param err any The error value caught around a menu build call.
---@return boolean is_yield
function menu_api.is_init_yield(err) end

---Build counters for the current staged build, refreshed on every call.
---@return menu_build_stats stats
function menu_api.get_build_stats() end

---@class menu_build_stats
---@field created integer Widgets constructed during this build.
---@field reused integer Widgets reused from the retained tree.
---@field id_reused integer Widgets matched by explicit id.
---@field semantic_reused integer Widgets matched by structural position.
---@field units integer Build units spent so far this frame.
---@field mode "ready"|"discover"|"materialize" The active build mode.

---True while a staged build is in progress (mode is not `ready`).
---@return boolean
function menu_api.is_initializing() end

---True while the staged build is in its `materialize` pass.
---@return boolean
function menu_api.is_materializing() end
-- [/WOW ONLY]

---Renders a static text row at the current container position.
---Each \n-separated line becomes its own row.
---@param text string
---@param text_color? color_helper IGNORED — pass opts.color_key instead
---@param opts? { color_key?: string } Theme tint key ("warning", "danger", ...)
function menu_api.header(text, text_color, opts) end

---Renders a horizontal separator at the current container position
---@param opts? table Legacy styling — ignored
function menu_api.separator(opts) end

-- =============================================================================
-- FRAME LIFECYCLE (driven by the menu host — plugins normally never call these)
-- =============================================================================

---Opens the per-frame walk. Must run before any element :render this frame.
---The menu host / bridge drives this; plugin code should not call it.
function menu_api.begin_frame() end

---True when begin_frame throttled this frame (menu closed, post-warmup,
---non-Nth frame): every :render call no-ops. Value getters/setters are
---unaffected. Use to skip expensive menu-building work on throttled frames.
---@return boolean
function menu_api.is_skip_frame() end

---Runs `fn` with an existing NATIVE `_G.menu` page as the current container, so
---each tree/element rendered inside lands as a section on that page instead of
---minting its own top-level page. No-ops when the page doesn't exist.
---@param page_path string|string[] Page path, e.g. { "Core", "Settings" }
---@param fn fun()
function menu_api.render_into_page(page_path, fn) end

-- =============================================================================
-- RETIRED ENTRY POINTS (kept as no-ops so old callers don't error)
-- =============================================================================

---RETIRED no-op (the new menu renders itself)
function menu_api.set_default_window(win) end

---RETIRED: returns `obj` unchanged
---@generic T
---@param obj T
---@param win window
---@return T obj
function menu_api.bind_window(obj, win) end

---Creates a bound factory (the window is ignored by the shim; constructors
---behave exactly like the module-level new_* functions)
---@param window window
---@return menu_bound_factory
function menu_api.bind(window) end

---RETIRED no-op
function menu_api.render_tree_headers(left_window) end

---RETIRED no-op
function menu_api.render_attached_elements(right_window) end

---RETIRED no-op
function menu_api.render_layout() end

---RETIRED no-op
function menu_api.render_control_panel_to_window() end

---RETIRED: always returns an empty result list
---@return table[]
function menu_api.search(term, opts) end

---RETIRED: always returns false
---@return boolean
function menu_api.navigate_to(id) end

---RETIRED no-op
function menu_api.render_search_results(win, results) end

---RETIRED: returns two empty tables
---@return table, table
function menu_api.iter_layout() end

-- =============================================================================
-- INTERNATIONALIZATION
-- =============================================================================

---@class menu_i18n
---@field language_files table<string, string> Map of language name → filename
---@field SHOULD_EXPORT boolean When true, newly-seen labels are collected for translators
menu_api.i18n = {}

---Writes collected labels to the translation files
function menu_api.i18n.flush_new_labels_to_files() end

---Enable/disable label collection
---@param state boolean
function menu_api.i18n.set_collecting(state) end

---@return string[]
function menu_api.i18n.get_collected_labels() end

return menu_api
