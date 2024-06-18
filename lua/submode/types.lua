---@class Submode
---@field state SubmodeState Internal state of submode

---@class SubmodeState
---@field current_mode string Represent current mode, or empty string if not in submode.
---@field submode_to_opts table<string, SubmodeOpts> Infomation of the submode.
---@field submode_to_user_mappings table<string, SubmodeMappings> User mappings of the submode.
---@field submode_to_default_mappings table<string, SubmodeMappings> Default mappings of the submode.
---@field snapshot SnapshotManager
---@field leave_bufs integer[] Buffers where leave key registered.

---@class SubmodeOpts
---@field mode ShortenMode
---@field show_mode? boolean
---@field mode_name? string | fun():string
---@field enter? string | string[]
---@field leave? string | string[]
---@field default? fun(register: SubmodeDefaultMappingRegister)
---@field leave_when_mode_changed? boolean
---@field override_behavior? "error" | "keep" | "override"

---Combination of lhs and element.
---@alias SubmodeMappings table<SubmodeMappingLhs, SubmodeMappingElement>
---@alias SubmodeMappingLhs string

---Infomation of mapping except lhs.
---@class SubmodeMappingElement
---@field rhs string | fun():string?
---@field opts? vim.keymap.set.Opts

---@alias SubmodeDefaultMappingRegister fun(lhs: string, rhs: string | function, opts: vim.keymap.set.Opts?)
