---@class Submode
---@field current_mode string Represent current mode, or empty string if not in submode.
---@field submode_to_info table<string, SubmodeInfo> Infomation of the submode.
---@field submode_to_mappings table<string, SubmodeMappings> Mappings of the submode.
---@field snapshot SnapshotManager
---@field config SubmodeSetupConfig Config of this plugin.
---@field leave_bufs integer[] Buffers where leave key registered.

---@class SubmodeInfo
---@field mode string
---@field show_mode? boolean
---@field enter? string | string[]
---@field leave? string | string[]
---@field enter_cb? function
---@field leave_cb? function

---Combination of lhs and element.
---@alias SubmodeMappings table<SubmodeMappingLhs, SubmodeMappingElement>
---@alias SubmodeMappingLhs string

---Infomation of mapping except lhs.
---@class SubmodeMappingElement
---@field rhs string | fun(lhs: string):string?
---@field opts? table

---Mapping infomation which user pass.
---@class SubmodeMappingPre
---@field lhs string | string[]
---@field rhs string | fun(lha: string):string?
---@field opts? table

---@class SubmodeSetupConfig
---@field leave_when_mode_changed boolean Leave from submode when parent mode is changed.
---@field when_mapping_exist WhenMappingExistType Behavior when mapping conflict.
---@field when_submode_exist WhenSubmodeExistType Behavior when submode exist.

---@alias WhenMappingExistType "error" | "keep" | "override"
---@alias WhenSubmodeExistType "error" | "keep" | "override"

---@class SubmodeEnterOptions
---@field callback? function Callback which will be called when enter the submode.

---@class SubmodeLeaveOptions
---@field callback? function Callback which will be called when leave from submode.
