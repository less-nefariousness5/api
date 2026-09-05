---@meta

---@class quick_logs_perf_stats
---@field queued_bytes integer
---@field enqueued_bytes integer
---@field writes integer
---@field written_bytes integer
---@field max_write_ms number
---@field flush_interval number
---@field largest_path_bytes integer
---@field over_cap_paths integer

---@class quick_logs_create_options
---@field ext? string
---@field header? string
---@field is_active? fun(): boolean

---@class quick_logs_logger
---@field is_active fun(): boolean
---@field write fun(content: any)
---@field write_raw fun(content: any)
---@field writef fun(fmt: string, ...)
---@field separator fun()
---@field header fun(title: string)
---@field get_path fun(): string
--- The logger is also callable: `logger(fmt, ...)` writes one line prefixed
--- with the uptime and game time, formatting through string.format. The
--- language server's `@operator call` takes a single parameter type and cannot
--- describe the variadic form, so it is documented here instead of annotated.
--- `writef` is the equivalent with a checked signature.

---@class quick_logs_library
---@field get_session_id fun(): string
---@field set_debug_gate fun(fn: fun(): boolean)
---@field is_debug_mode fun(): boolean
---@field ensure fun(module_name: string, file_name: string): string
---@field ensure_root fun(module_name: string, file_name: string): string
---@field get_path fun(module_name: string, file_name: string): string
---@field flush fun()
---@field get_perf_stats fun(out?: quick_logs_perf_stats): quick_logs_perf_stats
---@field append fun(module_name: string, file_name: string, content: string)
---@field append_path fun(path: string, content: string)
---@field write fun(module_name: string, file_name: string, content: any)
---@field writef fun(module_name: string, file_name: string, fmt: string, ...)
---@field write_session_pointer fun(module_name: string)
---@field create fun(module_name: string, file_name: string, opts?: quick_logs_create_options): quick_logs_logger

---@type quick_logs_library
quick_logs = nil
