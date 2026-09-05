---@diagnostic disable: duplicate-set-field, duplicate-doc-field, missing-return

---@meta

-- =============================================================================
-- NEW DECLARATIVE MENU — LuaLS stub for `_G.menu` (common/menu/api.lua).
--
-- This is the RECOMMENDED surface for new plugins. Content is declared ONCE
-- (retained mode) as pages → sections → widgets; the menu renders itself and
-- persists values across reloads automatically.
--
--   local menu = _G.menu                        -- installed by the menu host
--   local page = menu:page({ "My Plugin" }, { icon = "widgets" })
--   local s = page:section("General", nil, { column = "full" })
--   s:checkbox("enabled", "Enable plugin", true)
--   s:slider("range", "Attack range", 0, 100, 40, "%")
--   -- reading values (anywhere, every frame is fine — plain table read):
--   local on = menu:get("My Plugin", "enabled")
--
-- Value shapes by widget kind (what menu:get returns / menu:set expects):
--   toggle/checkbox → boolean          slider           → number
--   dropdown/radio/tabs/color → integer (1-based index)
--   keybind         → menu_keybind_value               text_input → string
--   color_picker    → menu_rgba
--   multi_select    → boolean[] mask (mask[i] == option i selected)
--   priority_list/reorderable_dropdown → integer[] permutation (slot → option index)
--
-- Widget `id`s are the persistence key (salted with the page path). NEVER
-- rename an id or move its widget to another page casually — the saved value
-- is orphaned and the widget resets to its default.
--
-- See menu_info.md at the scripts root for the full system guide.
-- =============================================================================
--
-- AUTHORING CHECKLIST
-- -------------------
-- * Register pages/widgets once during plugin load, never once per frame.
-- * The declared default is both the first-run value and right-click reset
--   value. Use menu:set for a live change; do not redeclare the widget.
-- * Poll with menu:get(path, id). Use menu:on_change only for side effects that
--   must happen immediately.
-- * Labels are presentation. Page path + widget id is permanent identity.
--
-- KEYBIND COOKBOOK (WoW MODIFIER CHORDS ARE SUPPORTED)
-- ----------------------------------------------------
-- `mode` defaults to "hold". With `modes` omitted, the mode is locked:
--
--   s:keybind("interrupt", "Interrupt", 0x54, {
--       mode = "hold",
--       default_mods = { ctrl = true, shift = false, alt = false },
--   })
--
-- To let the user change behavior, provide only the choices you support, in the
-- desired double-click cycle order. This bind can switch toggle <-> hold and
-- can never enter release:
--
--   s:keybind("monitor", "Performance monitor", 0x54, {
--       mode = "toggle",
--       modes = { "toggle", "hold" },
--       default_active = false,
--       default_mods = { ctrl = true, shift = false, alt = false },
--   })
--
-- A single valid entry also locks the badge. Add "release" only when the plugin
-- really implements/wants release behavior:
--
--   modes = { "hold", "toggle", "release" }
--
-- Click the key pill and press the chord to rebind. Double-click the mode badge
-- within 0.40 seconds to advance through `modes`. A failed single click waits
-- for that window, then shows "Changing keybind type" once per session; a
-- successful double-click stays silent. "Don't remind me again" persists at
-- scripts_data/menu/keybind_mode_hint.txt.
--
-- Mode meanings:
-- * hold    - active only while the full key + modifier chord is down.
-- * toggle  - latched state flips when the chord is pressed.
-- * release - latched state flips when the chord is released.
--
-- `default_active` only seeds the session's toggle/release latch; live active
-- state is not persisted. Modifier chords are a WoW-specific capability. Code
-- shared with LoL/Overwatch must not require `default_mods`: those games bind
-- Ctrl/Shift/Alt as standalone keys so a user can bind Control alone.
--
-- VISIBILITY, PERMASHOW, AND STORAGE
-- ---------------------------------
-- `visible` may be a boolean or function on pages, sections, and supported
-- widgets; invisible pages also disappear from global search. Use
-- menu.permashow.add(path, id) to mirror a supported value and
-- menu:show_confirm({...}) for warning/danger actions. Menu-owned assets,
-- persistence, onboarding, translations, and hints live below
-- scripts_data/menu/. Plugins should not edit those internal files directly.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Value shapes
-- -----------------------------------------------------------------------------

---@class menu_keybind_mods
---@field ctrl boolean
---@field shift boolean
---@field alt boolean

---@class menu_keybind_value
---@field vk integer Virtual-key code (0 or 999 = unbound)
---@field mods menu_keybind_mods Required modifier keys
---@field mode "hold"|"toggle"|"release" Trigger mode
---@field active boolean Live state. hold: true while the combo is held. toggle: latch, flips on key press. release: latch, flips on key RELEASE (press does nothing until the key is lifted). Runtime-only — not persisted.

---@class menu_rgba
---@field r integer 0..255
---@field g integer 0..255
---@field b integer 0..255
---@field a integer 0..255

-- -----------------------------------------------------------------------------
-- Widget option tables
-- -----------------------------------------------------------------------------

-- Locked-widget badge. Any widget opts table accepts `lock`, in three forms:
-- a requirement string ("Prediction Pro"), `true` for a generic lock, or this
-- table. It paints a star in a gutter at the left of the row and pops a
-- tooltip naming what unlocks the widget while the cursor is on the star.
-- `lock` implies `disabled` at declare time unless `disables = false`.
-- Colors accept {r,g,b,a} or {r=,g=,b=,a=}; omit either for the menu default.
---@class menu_lock_opts
---@field requires? string Fills the default body, "Requires <requires> to unlock".
---@field text? string Replaces the default body outright.
---@field title? string Tooltip title. Defaults to the widget's label.
---@field tooltip? boolean Set false for the badge with no tooltip at all.
---@field accent_color? number[]|{r:number,g:number,b:number,a?:number} Tooltip top + left lines, and the star itself.
---@field text_color? number[]|{r:number,g:number,b:number,a?:number} Tooltip body text.
---@field icon? "star"|"lock" Badge art. Default "star".
---@field disables? boolean Set false to keep the widget interactive under the badge.

---@alias menu_lock string|boolean|menu_lock_opts

---@class menu_toggle_opts
---@field disabled? boolean Grey out and ignore input
---@field lock? menu_lock Gate the row behind something: star badge plus a "Requires X to unlock" tooltip. Implies `disabled`.
---@field description? string Hover tooltip
---@field visible? boolean|fun(): boolean Visibility gate, re-evaluated per frame when a function
---@field permashow_label? string Display-name override used only by the permashow mirror

---@class menu_slider_opts
---@field integer? boolean Force integer (true) or float (false) mode. Default: integer when (max - min) >= 2 and no step given.
---@field step? number Snap granularity (value snaps to min + step*k). Giving a step defaults the slider to float mode.
---@field disabled? boolean
---@field lock? menu_lock Star badge plus a "Requires X to unlock" tooltip. Implies `disabled`.
---@field description? string Hover tooltip
---@field visible? boolean|fun(): boolean Visibility gate, re-evaluated per frame when a function
---@field permashow_label? string Display-name override used only by the permashow mirror

---@class menu_dropdown_opts
---@field disabled? boolean
---@field lock? menu_lock Star badge plus a "Requires X to unlock" tooltip. Implies `disabled`.
---@field description? string Hover tooltip
---@field visible? boolean|fun(): boolean Visibility gate, re-evaluated per frame when a function
---@field permashow_label? string Dropdown-only display-name override used by the permashow mirror

---@class menu_button_opts
---@field description? string Hover tooltip
---@field disabled? boolean
---@field lock? menu_lock Star badge plus a "Requires X to unlock" tooltip. Implies `disabled`.
---@field icon? string Icon catalog key (see common/menu/icons.lua M.map)
---@field style? "default"|"primary"|"danger"|"ghost"
---@field on_click? fun() Fired on click (during the render pass)
---@field permashow_label? string Display-name override used only by the permashow mirror
---@field visible? boolean|fun(): boolean Visibility gate, re-evaluated per frame when a function

---@class menu_icon_button_opts: menu_button_opts
---@field icon_size? number Icon px (default 32)
---@field text_pos? "below"|"above"|"left"|"right"|"none" Caption placement (default "below")
---@field text_gap? number Px between icon and caption (default 6)
---@field label_size_key? string Font size key for the caption (default "small")
---@field button_w? number Absolute button width px
---@field button_h? number Absolute button height px (default 64)

---@class menu_keybind_opts
---@field default_mods? menu_keybind_mods Modifier keys required by the default bind
---@field mode? "hold"|"toggle"|"release" Default trigger mode (default "hold"; must be in `modes` when that is given, else it snaps to the first allowed). "release" latches like toggle but flips on key-up instead of key-down.
---@field modes? ("hold"|"toggle"|"release")[] Exact trigger modes offered in double-click cycle order. Omit or give one valid entry to lock; release is opt-in.
---@field default_active? boolean Seed toggle/release runtime state active for this session; runtime state is not persisted
---@field description? string Hover tooltip
---@field disabled? boolean
---@field lock? menu_lock Star badge plus a "Requires X to unlock" tooltip. Implies `disabled`.
---@field confirm_rebind? boolean Require explicit confirmation, then a second click, before key capture
---@field permashow_label? string Display-name override used only by the permashow mirror
---@field visible? boolean|fun(): boolean Hide this keybind row while false

---@class menu_text_input_opts
---@field placeholder? string Ghost text while empty
---@field max_len? integer Max characters (default 64)
---@field disabled? boolean
---@field lock? menu_lock Star badge plus a "Requires X to unlock" tooltip. Implies `disabled`.
---@field description? string Hover tooltip
---@field visible? boolean|fun(): boolean Visibility gate, re-evaluated per frame when a function

---@class menu_color_opts
---@field palette? integer[][] Array of {r,g,b} rows to cycle through (default: the menu's purple+magenta set)
---@field disabled? boolean
---@field lock? menu_lock Star badge plus a "Requires X to unlock" tooltip. Implies `disabled`.

---@class menu_color_picker_opts
---@field description? string Hover tooltip
---@field disabled? boolean
---@field lock? menu_lock Star badge plus a "Requires X to unlock" tooltip. Implies `disabled`.
---@field show_alpha? boolean Show the alpha bar (default true)
---@field visible? boolean|fun(): boolean Visibility gate, re-evaluated per frame when a function

---@class menu_list_opts
---@field description? string Hover tooltip
---@field disabled? boolean
---@field lock? menu_lock Star badge plus a "Requires X to unlock" tooltip. Implies `disabled`.
---@field visible? boolean|fun(): boolean Visibility gate, re-evaluated per frame when a function (priority_list forwards this since 2026-07-31)

---@class menu_progress_opts
---@field source? fun(page_values: table<string, any>): number Returns fill 0..1, re-evaluated every frame (nil = demo animation)
---@field color? any Fill color override

---@class menu_label_opts
---@field color_key? string Theme palette key for the tint ("tx", "tx_dim", "warning", "danger", ...)
---@field size_key? string Font size key (default "body")
---@field visible? boolean|fun(): boolean Visibility gate, re-evaluated per frame when a function

---@class menu_subsection_opts
---@field collapsed? boolean Spawn collapsed (default true)
---@field id? string Stable identity for the collapse animation/persistence when the label alone is ambiguous
---@field description? string Hover tooltip on the header
---@field icon? fun(w: table, x: number, y: number, size: number) Custom icon draw callback next to the header label
---@field icon_position? "before"|"after" (default "before")
---@field icon_size? number Px square (default 18)

---@class menu_section_opts
---@field column? "left"|"right"|"full" Layout slot: two-column grid or full-width row (default "left")
---@field order? number Cross-module sort key. Sections sort by it ascending before rendering; ties and sections without one keep declaration order. Only needed when a page's sections are registered by DIFFERENT modules, where declaration order is really module load order.
---@field width? number > 1.5 = absolute px; 0..1 = fraction of the slot width
---@field min_height? number Reserve at least this body height (px)
---@field max_height? number Cap the body height (only enforced when auto_height = false)
---@field auto_height? boolean Grow to fit content (default true)
---@field visible? boolean|fun(): boolean Visibility gate, re-evaluated per frame when a function
---@field center? boolean column="full" only: center the card instead of left-aligning
---@field collapsed? boolean Spawn collapsed (user can toggle by clicking the title strip)
---@field searchable? boolean Show a per-section search field that filters widgets by label

---@class menu_page_meta
---@field icon? string Sidebar icon catalog key (see common/menu/icons.lua M.map)
---@field badge? string Small badge text on the sidebar row
---@field visible? boolean|fun(): boolean Hide/show the page (and its sidebar row)
---@field label? string Sidebar display-name override (path segment stays the identity)

---@class menu_category_meta: menu_page_meta
---@field expanded? boolean Initial expand state (ignored when the user has a saved state)

---@class menu_title_opts
---@field size? "title"|"subtitle"|"body"|"small"|"micro" Font size key (default "title")
---@field align? "left"|"center"|"right" (default "center" since 2026-07-31; pass "left" for the old flush-to-the-edge look)
---@field color? any Palette color userdata or {r,g,b,a} (default: standard title color)
---@field pad_y? number Extra px after the title (default 8)

---@class menu_page_button_opts: menu_button_opts
---@field button_h? number Button height px
---@field accent_color? any Accent override
---@field width? number > 1.5 = absolute px, 0..1.5 = fraction of content width (default 280)
---@field align? "left"|"center"|"right" (default "center")
---@field pad_y? number Extra px after the button (default 8)

---@class menu_page_icon_button_opts: menu_icon_button_opts
---@field width? number Button width px (default 64)
---@field height? number Button height px (default 64)
---@field align? "left"|"center"|"right" Inline mode row alignment (default "center")
---@field anchor? "top-right"|"top-left" Float at a content-area corner instead of the row flow
---@field pad_x? number Anchored: px from the corner (default 22)
---@field pad_y? number Anchored: px from the corner (default 14)
---@field reserve_space? boolean Anchored: push the row layout below the button footprint (default false)
---@field accent_color? any Accent override

---@class menu_confirm_request
---@field title string Dialog title (tinted by `tone`)
---@field body string|string[] Body lines ("" = half-line spacer), or one string with \n breaks
---@field tone? "warning"|"danger" Border/title tint; "danger" also styles the confirm button
---@field confirm_label? string Primary button label (default "OK")
---@field cancel_label? string Safe button label (default "Cancel"), always clickable
---@field hide_cancel? boolean Only show the confirm button (single-button advisory)
---@field width? number Optional compact card width in pixels
---@field ack_text? string When set, confirm stays DISABLED until this checkbox is ticked
---@field remember_text? string When set, a non-gating "don't remind me" checkbox is shown; its state is passed to the callbacks
---@field on_remember_change? fun(remember: boolean) Fired immediately when the remember checkbox changes
---@field on_confirm? fun(remember: boolean) Fired only by the confirm button
---@field on_cancel? fun(remember: boolean) Fired only by the Cancel button

-- -----------------------------------------------------------------------------
-- Custom widget kinds (menu:register_kind)
-- -----------------------------------------------------------------------------

---@class menu_widget_ctx
---@field w window The menu window being painted (full SDF drawing API)
---@field theme table common/menu/theme.lua (palette T.p, spacing T.s, helpers T.tc/T.ca)
---@field fonts table common/menu/fonts.lua (push/pop + measure helpers)
---@field icons table common/menu/icons.lua (catalog + draw)
---@field page menu_page The page being rendered (page.values holds the live values)
---@field dt number Frame delta seconds
---@field t number Wall-clock seconds (core.time())
---@field state_for fun(widget: table): table Per-widget persistent animation-state table (keyed on widget identity)
---@field api menu_v2 The menu module itself
---@field nav_x number Content area's window-local x offset (add to convert local → screen)
---@field nav_y number Content area's window-local y offset
---@field rmb_reset_press_edge? boolean True on the frame WoW RMB was pressed (arms right-click-reset without enabling menu input)
---@field rmb_reset_release_edge? boolean True on the frame WoW RMB was released (commits only on the same armed widget)
---@field rmb_reset_hit? fun(page_path:string, widget:table, is_hit:boolean):boolean Tracks the WoW-only press/release reset gesture and returns true when the same widget should reset
---@field draw_anim? fun(...) Host GIF-overlay helper (nil outside the main content pass)

---@class menu_widget_kind_def
---@field measure fun(widget: table): number Returns the row height in px for layout
---@field render fun(ctx: menu_widget_ctx, widget: table, x: number, y: number, row_w: number): number Paints at (x, y) and returns the height actually consumed

-- -----------------------------------------------------------------------------
-- Section — a card of widgets inside a page column
-- -----------------------------------------------------------------------------

---@class menu_section
---@field title string Card title (mutable)
---@field page menu_page Owning page
---@field widgets table[] Raw widget records (advanced use)
---@field collapsed boolean Current collapse state
---@field visible boolean|fun(): boolean|nil Visibility gate
---@field column "left"|"right"|"full" Layout slot this card was registered in
--- Internal escape hatch: the renderer paints sections marked this way after
--- every other section on the page, whatever their declaration order.
---@field _render_last? boolean
local Section = {}

---On/off switch rendered as a sliding toggle. Value: boolean.
---@param id string Value key (unique within the page)
---@param label string Row label
---@param default? boolean
---@param opts? menu_toggle_opts
---@return menu_section self
function Section:toggle(id, label, default, opts) end

---On/off switch rendered as a checkbox. Value: boolean.
---@param id string Value key (unique within the page)
---@param label string Row label
---@param default? boolean
---@param opts? menu_toggle_opts
---@return menu_section self
function Section:checkbox(id, label, default, opts) end

---Draggable value slider. Value: number (rounded when integer mode).
---@param id string Value key
---@param label string Row label
---@param min number
---@param max number
---@param default number
---@param suffix? string Unit text after the value readout (e.g. "%", " ms")
---@param opts? menu_slider_opts
---@return menu_section self
function Section:slider(id, label, min, max, default, suffix, opts) end

---Single-choice dropdown. Value: integer (1-based index into `options`).
---@param id string Value key
---@param label string Row label
---@param options string[] Choice labels
---@param default_index? integer (default 1)
---@param opts? menu_dropdown_opts
---@return menu_section self
function Section:dropdown(id, label, options, default_index, opts) end

---Single-choice inline radio row. Value: integer (1-based index).
---@param id string Value key
---@param label string Row label
---@param options string[] Choice labels
---@param default_index? integer (default 1)
---@param opts? menu_dropdown_opts
---@return menu_section self
function Section:radio(id, label, options, default_index, opts) end

---Click button. No persisted value — react via opts.on_click.
---@param id string Widget key
---@param label string Button text
---@param opts? menu_button_opts
---@return menu_section self
function Section:button(id, label, opts) end

---Icon-first button (icon dominant, label as caption). No persisted value.
---@param id string Widget key
---@param label string Caption text
---@param opts? menu_icon_button_opts opts.icon is required
---@return menu_section self
function Section:icon_button(id, label, opts) end

---Key binding with modifier support and hold/toggle/release trigger modes.
---Value: menu_keybind_value — poll `menu:get(page, id).active` for the live
---state (hold: true while held; toggle: latch flipped on press; release:
---latch flipped on key-up). The declared default is locked unless the
---developer explicitly exposes multiple choices through opts.modes. Editable
---mode chips change only on a complete double-click within 0.40 seconds.
---@param id string Value key
---@param label string Row label
---@param default_vk? integer Virtual-key code (0 or 999 = unbound)
---@param opts? menu_keybind_opts
---@return menu_section self
function Section:keybind(id, label, default_vk, opts) end

---Single-line text field. Value: string.
---@param id string Value key
---@param label string Row label
---@param default? string
---@param opts? menu_text_input_opts
---@return menu_section self
function Section:text_input(id, label, default, opts) end

---Palette-cycle color swatch (click to cycle a fixed palette). Value: integer palette index.
---For a full RGBA picker use color_picker instead.
---@param id string Value key
---@param label string Row label
---@param default_index? integer 1-based palette index (default 1)
---@param opts? menu_color_opts
---@return menu_section self
function Section:color(id, label, default_index, opts) end

---Full RGBA color picker (SV square + hue bar + optional alpha bar). Value: menu_rgba.
---@param id string Value key
---@param label string Row label
---@param default_rgba? menu_rgba|integer[]|color_helper {r,g,b,a} table, {255,0,0} array, or a color_helper object
---@param opts? menu_color_picker_opts
---@return menu_section self
function Section:color_picker(id, label, default_rgba, opts) end

---Inline reorderable list (drag-handle rows). Value: integer[] permutation —
---order[slot] = index into `options`. Default is identity {1, 2, ..., n}.
---@param id string Value key
---@param label string Row label
---@param options string[] Item labels
---@param opts? menu_list_opts
---@return menu_section self
function Section:priority_list(id, label, options, opts) end

---Multi-selection dropdown (per-row checkboxes in the popover).
---Value: boolean[] mask — mask[i] == true iff option i is selected.
---@param id string Value key
---@param label string Row label
---@param options string[] Item labels
---@param default? integer[]|boolean[] Selected indices ({1,3}) or a literal mask ({true,false,...}); nil = none
---@param opts? menu_list_opts
---@return menu_section self
function Section:multi_select(id, label, options, default, opts) end

---Reorderable list inside a dropdown popover; the closed trigger shows the top item.
---Value: integer[] permutation (same semantics as priority_list).
---@param id string Value key
---@param label string Row label
---@param options string[] Item labels
---@param opts? menu_list_opts
---@return menu_section self
function Section:reorderable_dropdown(id, label, options, opts) end

---Progress bar. Value: number 0..1 (driven by opts.source when given).
---@param id string Value key
---@param label string Row label
---@param opts? menu_progress_opts
---@return menu_section self
function Section:progress(id, label, opts) end

---Horizontal tab strip. Value: integer (1-based active tab).
---@param id string Value key
---@param label string Row label
---@param options string[] Tab labels
---@param default_index? integer (default 1)
---@return menu_section self
function Section:tabs(id, label, options, default_index) end

---Thin horizontal rule, optionally labelled. No value.
---@param label? string
---@return menu_section self
function Section:separator(label) end

---Static single-line text row. No value. Width-truncates — split long text
---into multiple label() calls rather than embedding \n.
---@param text string
---@param opts? menu_label_opts
---@return menu_section self
function Section:label(text, opts) end

---Empty vertical gap. No value.
---@param h? number Px (default 6)
---@return menu_section self
function Section:spacer(h) end

---Collapsible labelled sub-group INSIDE this section (thin mini-card with its
---own chevron header). Child widgets are added on the returned wrapper with the
---same methods as a section. Nesting subsections is supported to arbitrary depth.
---@param title string
---@param opts? menu_subsection_opts
---@return menu_subsection
function Section:subsection(title, opts) end

---Insert a widget of a custom kind registered via menu:register_kind.
---`attrs` becomes the widget record (kind/id are filled in).
---@param kind string Registered kind name
---@param id string|nil Value key (nil for stateless widgets)
---@param attrs? table Extra widget fields your renderer reads
---@return menu_section self
function Section:custom(kind, id, attrs) end

-- -----------------------------------------------------------------------------
-- Subsection — same widget methods as a Section, nested inside one
-- -----------------------------------------------------------------------------

---@class menu_subsection: menu_section
local Subsection = {}

---Nest another collapsible subsection inside this one (arbitrary depth; each
---level indents +14 px and collapses independently).
---@param title string
---@param opts? menu_subsection_opts
---@return menu_subsection
function Subsection:subsection(title, opts) end

-- -----------------------------------------------------------------------------
-- Page — one sidebar leaf: a grid of sections plus standalone elements
-- -----------------------------------------------------------------------------

---One entry in a page's declaration-order render list.
---@class menu_page_element
---@field kind "section"|"title"|"button"|"icon_button" Which declaration produced this entry
--- The declared record. Its shape follows `kind`: a `menu_section` for
--- "section", otherwise the internal title / button / icon-button record built
--- by Page:title, Page:button or Page:icon_button. Read `kind` first.
---@field ref table
--- Marks the entry where a vertically centered sub-block begins. Only honored
--- while the owning page's `_vcenter` gate returns true.
---@field _vcenter_anchor? boolean

---@class menu_page
---@field path_str string Stable identity, path segments joined with "/" (use with menu:get / menu:set)
---@field path string[] The same identity as separate path segments, in sidebar order
---@field values table<string, any> Live widget values keyed by widget id (read OK; prefer menu:set for writes so observers fire)
---@field label string|nil Sidebar display-name override
---@field sections menu_section[]
--- Sections, titles and page-level buttons in declaration order. The render
--- loop walks this instead of `sections`, so a title can sit between two cards.
---@field elements menu_page_element[]
---@field owner string|nil Package folder that declared the page, resolved at registration
--- Internal: per-frame gate asking whether this page's `_vcenter_anchor` block
--- should be vertically centered in the content area.
---@field _vcenter? fun(): boolean
local Page = {}

---Standalone text band above/between the section grid (not inside a card).
---Renders at the point of the page where it was declared relative to section() calls.
---@param text string|fun(): string Static text or a per-frame provider
---@param opts? menu_title_opts
---@return menu_page self
function Page:title(text, opts) end

---Standalone button in the page flow (no section chrome). Same options as a
---section button plus width/align/pad_y.
---@param id string Widget key
---@param label string Button text
---@param opts? menu_page_button_opts
---@return menu_page self
function Page:button(id, label, opts) end

---Standalone icon button; inline in the flow, or floated at a content-area
---corner via opts.anchor ("top-right"/"top-left").
---@param id string Widget key
---@param label string Caption text
---@param opts? menu_page_icon_button_opts
---@return menu_page self
function Page:icon_button(id, label, opts) end

---Create a section card on this page. Sections stack into a two-column grid
---("left"/"right") or take a full-width row ("full").
---@param title string Card title
---@param icon? string Icon catalog key drawn in the card header
---@param opts? menu_section_opts
---@return menu_section
function Page:section(title, icon, opts) end

-- -----------------------------------------------------------------------------
-- Permashow — always-on-screen mirror of chosen widgets
-- -----------------------------------------------------------------------------

---@class menu_permashow
local Permashow = {}

---True when this widget kind can be mirrored (toggle/checkbox/slider/dropdown/keybind/...).
---@param kind string
---@return boolean
function Permashow.is_supported_kind(kind) end

---Mirror a widget onto the permashow window. (Users do this with Ctrl+Click on the widget.)
---@param page_path string|string[] Page path_str or path segments, e.g. "My Plugin" or {"My Plugin"}
---@param widget_id string
function Permashow.add(page_path, widget_id) end

---Remove a mirrored widget.
---@param page_path string|string[]
---@param widget_id string
function Permashow.remove(page_path, widget_id) end

---Add if absent, remove if present.
---@param page_path string|string[]
---@param widget_id string
function Permashow.toggle_mirror(page_path, widget_id) end

---@param page_path string|string[]
---@param widget_id string
---@return boolean
function Permashow.is_mirrored(page_path, widget_id) end

---Return the stable marker path used by product-specific default-pin seeders.
---@param seed_id string
---@return string
function Permashow.seed_file(seed_id) end

---Remove every mirrored widget.
function Permashow.clear() end

---@return table[] items The mirrored { page_path, widget_id } records
function Permashow.get_items() end

---@return boolean
function Permashow.is_visible() end

---@param v boolean
function Permashow.set_visible(v) end

function Permashow.toggle_visible() end

---Reset the permashow window back to its default screen position.
function Permashow.reset_position() end

-- -----------------------------------------------------------------------------
-- Control panel (also _G.menu.control_panel)
--
-- Two ways to put an element on the permashow control panel:
--   1. New/simple: menu.control_panel.add(element[, lock]) - hand it a keybind or
--      combobox once at setup; it renders every frame, no callback needed.
--   2. Legacy: register an on_render_control_panel callback returning an element
--      array (see common/utility/control_panel_helper). Those rows are mirrored
--      automatically - kept for drop-in compatibility with existing plugins.
-- Either way the user can Ctrl+Click a row to hide it, unless the plugin locks it
-- (add(el, true) / lock / set_removable).
-- -----------------------------------------------------------------------------

---@class menu_control_panel
local ControlPanel = {}

---Put an element on the permashow control panel directly (no callback needed).
---The simple path for new plugins. Call once at setup; idempotent (re-adding the
---same element updates it in place). Auto-detects keybind (toggle) vs combobox
---(combo) and names the row from the element's label.
---@param element table|userdata A keybind or combobox (or a { name=, keybind|combobox= } table for an explicit name)
---@param lock? boolean true forbids user removal; false/nil leaves it removable (default)
---@return boolean ok false if `element` isn't a supported element
function ControlPanel.add(element, lock) end

---Remove an element previously added with add(). Pass the same element (or its
---table). No-op if it wasn't added. Does not affect legacy callback rows.
---@param element table|userdata
---@return boolean ok
function ControlPanel.remove(element) end

---Forbid the user from removing this control-panel element from the overlay.
---Call once at setup. `target` is the keybind/combobox you built, or the
---{ name=, keybind|combobox= } table you return each frame.
---@param target table|userdata
---@return boolean ok
function ControlPanel.lock(target) end

---Allow removal again (undo lock).
---@param target table|userdata
---@return boolean ok
function ControlPanel.unlock(target) end

---Explicit form of lock/unlock. removable=false forbids removal.
---@param target table|userdata
---@param removable boolean
---@return boolean ok
function ControlPanel.set_removable(target, removable) end

---@param key string Stable element key (advanced; usually you pass an element to lock)
---@return boolean
function ControlPanel.is_locked(key) end

-- -----------------------------------------------------------------------------
-- Toast notifications (also exposed as _G.toast)
-- -----------------------------------------------------------------------------

---@class menu_toast_opts
---@field duration? number Seconds on screen
---@field fade_in? number Seconds
---@field fade_out? number Seconds

---@class menu_toast
local Toast = {}

---Green success toast. printf-style: toast.success("Saved %d items", n).
---Pass a menu_toast_opts table as the FIRST arg for per-call overrides:
---toast.success({duration = 6}, "Long message").
---@param fmt_or_opts string|menu_toast_opts
---@param ... any
function Toast.success(fmt_or_opts, ...) end

---Red error toast. Same calling conventions as success.
---@param fmt_or_opts string|menu_toast_opts
---@param ... any
function Toast.error(fmt_or_opts, ...) end

---Amber warning toast. Same calling conventions as success.
---@param fmt_or_opts string|menu_toast_opts
---@param ... any
function Toast.warning(fmt_or_opts, ...) end

---Set global defaults for every subsequent toast (any subset of the keys).
---@param opts menu_toast_opts
function Toast.set_defaults(opts) end

-- -----------------------------------------------------------------------------
-- The menu module (_G.menu)
-- -----------------------------------------------------------------------------

---A pending "scroll to and pulse this widget" request. Single-slot queue:
---several requests in one frame are last-write-wins.
---@class menu_highlight_request
---@field page_path string Target page path_str
---@field widget_id string Target widget id within that page
---@field subsection_label? string Uncollapse this subsection on the way
--- Extend the existing pulse ring's lifetime only: no navigate, no uncollapse
--- and no re-stamped scroll budget. The tutorial posts this every frame.
---@field refresh_only boolean

---@class menu_v2
---@field pages table<string, menu_page> Registered pages by path_str
---@field active_path string|nil path_str of the page currently shown
---@field tree table Sidebar node tree (advanced use)
---@field widget_kinds table<string, menu_widget_kind_def> Registered widget renderers
---@field permashow menu_permashow
---@field control_panel menu_control_panel
--- Bumped by every widget-creation path so consumers can rebuild cached
--- widget lists by comparing generations instead of re-walking every page.
---@field _widget_gen integer
--- Menu profiling facade (common/menu/profiler.lua). It lives on the module
--- rather than a file local because the main overlay callback already sits at
--- LuaJIT's 60-upvalue ceiling and `api` is captured there anyway. The fields
--- below share that reason.
---@field menu_profiler menu_profiler_facade
---@field _t_prev number|nil Previous frame's core.time(), nil before the first frame
---@field _flush_was_vis boolean Menu visibility at the last persistence flush
---@field _wiz_modal table|nil Guided-setup wizard state owned by the Settings Manager
---@field _user_navigated boolean True once the user picked a sidebar row this session
---@field _pending_highlight_request menu_highlight_request|nil Drained at the start of each frame
---@field _cursor_over_ui boolean True while the cursor is over any menu-owned window
local M = {}

---Create (or fetch) a page. `path` nests in the sidebar: { "Category", "Leaf" }
---puts "Leaf" under the expandable "Category" node. A "/"-joined string is
---accepted too. `meta` is merged on every call (icon only needs passing once).
---@param path string[]|string
---@param meta? menu_page_meta
---@return menu_page
function M:page(path, meta) end

---Create/update a sidebar category node that has no page of its own — use to
---give a parent node an icon before its child pages register.
---@param path string[]|string
---@param meta? menu_category_meta
---@return table node
function M:category(path, meta) end

---Navigate the menu to a page.
---@param path string[]|string path or path_str
function M:set_active(path) end

---@return menu_page|nil
function M:get_active_page() end

---Resolves function-valued visibility gates.
---@param page_path string
---@return boolean
function M:is_page_visible(page_path) end

---Read a widget value. See the header comment for the value shape per kind.
---@param page_path string Page path_str (segments joined with "/")
---@param id string Widget id
---@return any
function M:get(page_path, id) end

---Write a widget value (fires on_change observers when it actually changes).
---@param page_path string
---@param id string
---@param value any
function M:set(page_path, id, value) end

---Observe a widget value. `fn(new_value, old_value)` fires on every actual change
---(user edit or menu:set). Observers accumulate — register once at load, not per frame.
---@param page_path string
---@param id string
---@param fn fun(new_value: any, old_value: any)
function M:on_change(page_path, id, fn) end

---Fire the on_change observers for one widget. Plumbing, not a plugin entry point:
---the renderer calls this after writing a value the user edited by hand, which is
---what makes on_change fire for user edits as well as menu:set. Plugins should
---call menu:set and let it notify.
---
---Accepts a page table or a page path string. Observers are pcall'd, because this
---runs inside the render loop and a throwing observer would take the frame down.
---@param page_or_path table|string Page table (as held by the renderer) or page path_str
---@param id string Widget id
---@param new_value any
---@param old_value any
function M:notify_change(page_or_path, id, new_value, old_value) end

---Reset a widget to its declared default (deep-copied; fires observers).
---This is what the right-click-reset gesture calls.
---@param page_path string
---@param widget_id string
---@return boolean success false when the page/widget is unknown or has no default
function M:reset_widget(page_path, widget_id) end

---Lock or unlock a widget at runtime, without holding its handle. Writes BOTH
---`lock` and `disabled`, so gating a feature from a licence or entitlement
---callback needs nothing but the page path and the widget id. Pass nil to
---unlock. The badge and its "Requires X to unlock" tooltip are declared the same
---way through `opts.lock` on any widget constructor.
---@param page_path string|string[]
---@param widget_id string
---@param spec? menu_lock nil or false unlocks
---@return boolean found true when a widget with that id exists on the page
function M:set_lock(page_path, widget_id, spec) end

---Flush changed values + UI state to the persistence shadows. Driven by the
---menu host on a cadence — plugins normally never call this.
function M:flush_persistence() end

---Queue one widget's persistence shadow for the next flush.
---@param page_or_path menu_page|string
---@param widget_or_id table|string
function M:mark_persistence_dirty(page_or_path, widget_or_id) end

---Queue every persistence shadow on a page for the next flush.
---@param page_or_path menu_page|string
function M:mark_page_persistence_dirty(page_or_path) end

---Mark UI state (collapse/scroll/active page) dirty so the debounced disk write
---picks it up. Pass immediate=true for one-shot user actions that must survive
---a quick reload.
---@param immediate? boolean
function M:mark_ui_dirty(immediate) end

---Report a page's scroll position (host render path calls this every frame).
---@param page_path string
---@param scroll_y number
function M:report_scroll(page_path, scroll_y) end

---@param page_path string
---@return number scroll_y
function M:get_saved_scroll(page_path) end

---Restore the saved active page once plugin pages have registered (host calls this).
function M:restore_active_from_persistence() end

---Raise a blocking confirmation modal over the menu. A hosted dialog stays
---pending while the menu is hidden/minimized and only its own buttons resolve
---it. The headless fallback still resolves as CANCEL.
---@param req menu_confirm_request
function M:show_confirm(req) end

---True while the main menu surface is visible (shown and not minimized).
---@return boolean
function M:is_surface_open() end

---True when the cursor is over any menu-owned window (main window, launcher,
---popovers, permashow). Use it to suppress your own overlay's click handling
---while the menu covers it.
---@return boolean
function M:is_cursor_over_ui() end

---Un-minimize + show the main menu window. Safe to call when already visible.
function M:show_main_window() end

---Navigate to a page, uncollapse the path to a widget, and pulse a highlight
---ring on it (the search/tutorial affordance).
---@param page_path string[]|string
---@param widget_id string
---@param opts? { subsection_label?: string, refresh_only?: boolean } refresh_only extends the ring without re-navigating
function M:request_widget_highlight(page_path, widget_id, opts) end

---Register a custom widget kind usable via Section:custom(kind, ...).
---The renderer owns everything: layout, painting, interaction.
---@param kind string
---@param def menu_widget_kind_def
function M:register_kind(kind, def) end

-- -----------------------------------------------------------------------------
-- Globals installed by the menu host (common/menu/ps_menu_main.lua)
-- -----------------------------------------------------------------------------

---@type menu_v2
menu = menu or {}
_G.menu = menu

---@type menu_toast
toast = toast or {}
_G.toast = toast

---@type menu_permashow
permashow = permashow or {}
_G.permashow = permashow

return M
