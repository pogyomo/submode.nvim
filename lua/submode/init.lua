local utils = require("submode.utils")
local mode  = require("submode.mode")
local snapshot = require("submode.snapshot")

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
---@alias SubmodeMappingLhs string
---@alias SubmodeMappings table<SubmodeMappingLhs, SubmodeMappingElement>

---Infomation of mapping except lhs.
---@class SubmodeMappingElement
---@field rhs string | fun(lhs: string):string?
---@field opts? table

---Mapping infomation which user pass.
---@class SubmodeMappingPre
---@field lhs string | string[]
---@field rhs string | fun(lha: string):string?
---@field opts? table

---@alias WhenMappingExistType "error" | "keep" | "override"
---@alias WhenSubmodeExistType "error" | "keep" | "override"
---@class SubmodeSetupConfig
---@field leave_when_mode_changed boolean Leave from submode when parent mode is changed.
---@field when_mapping_exist WhenMappingExistType Behavior when mapping conflict.
---@field when_submode_exist WhenSubmodeExistType Behavior when submode exist.

---@class SubmodeEnterOptions
---@field callback? function Callback which will be called when enter the submode.

---@class SubmodeLeaveOptions
---@field callback? function Callback which will be called when leave from submode.

---Convert SubmodeMappingPre to SubmodeMappings.
---This doesn't affect to map.rhs and map.opts.
---@param map SubmodeMappingPre
---@return SubmodeMappings
local function convert_map_pre_to_maps(map)
    vim.validate{
        map = { map, "table" }
    }

    local ret = {}
    local listlized_lhs = utils.listlize(map.lhs)
    for _, lhs in ipairs(listlized_lhs) do
        ret[lhs] = {
            rhs  = map.rhs,
            opts = map.opts
        }
    end
    return ret
end

---Validate config.
---@param config SubmodeSetupConfig Config to validate.
local function validate_config(config)
    vim.validate{
        leave_when_mode_changed = {
            config.leave_when_mode_changed,
            "boolean"
        },
        when_mapping_exist = {
            config.when_mapping_exist,
            function(s)
                return utils.is_one_of_them(s, {
                    "error", "keep", "override"
                })
            end,
            "error, keep or override"
        },
        when_submode_exist = {
            config.when_submode_exist,
            function(s)
                return utils.is_one_of_them(s, {
                    "error", "keep", "override"
                })
            end,
            "error, keep or override"
        }
    }
end

---Default state of this plugin
---@class Submode
local default_state = {
    current_mode = "",
    submode_to_info = {},
    submode_to_mappings = {},
    snapshot = snapshot:new(),
    config = {
        leave_when_mode_changed = false,
        when_mapping_exist = "error",
        when_submode_exist = "error"
    },
    leave_bufs = {}
}

---@class Submode
local M = {}

---Initialize this plugin's state.
---All mappings and config will be lost.
function M:__initialize_state()
    for key, state in pairs(default_state) do
        -- NOTE: If I don't use deepcopy, table is stored as reference.
        --       I wan't to use default_state as constant table, but this may change
        --       its contents. So, I prevent this problem by using deepcopy.
        self[key] = vim.deepcopy(state)
    end
end

---Detect submode confliction.
---@param name string Name of submode.
---@return boolean # True if submode exist and when_submode_exist isn't override.
function M:__detect_submode_confliction(name)
    if self.config.when_submode_exist == "error" then
        if self.submode_to_info[name] then
            error(("Submode %s already exist."):format(name))
            return true
        end
        return false
    elseif self.config.when_submode_exist == "keep" then
        return self.submode_to_info[name] ~= nil
    else
        return false
    end
end

---Detect mapping confliction.
---@param name string Name of submode to check.
---@param lhs string Lhs of the mapping.
---@return boolean # True if mapping exist and when_mapping_exist isn't override.
function M:__detect_mapping_confliction(name, lhs)
    if self.config.when_mapping_exist == "error" then
        if not self.submode_to_mappings[name][lhs] then
            return false
        end
        local err_msg = "Mapping confliction detected in %s: %s is already defined."
        error(err_msg:format(name, lhs))
        return true
    elseif self.config.when_mapping_exist == "keep" then
        return self.submode_to_mappings[name][lhs] ~= nil
    else
        return false
    end
end

---Initialize submode.nvim
---@param config? SubmodeSetupConfig
function M:setup(config)
    vim.validate{
        config = { config, { "table", "nil" } }
    }

    -- NOTE: I initialize internal state because if the settings of this plugin
    --       is reloaded (i.e. PackerCompile) and when_mapping_exist is error,
    --       error occure. This happen because create or register called although
    --       its settings is already exist. So this prevent the error.
    self:__initialize_state()

    -- Initialize config with given config.
    self.config = vim.tbl_extend("keep", config or {}, self.config)
    validate_config(self.config)

    -- Create autocommand to exit submode when
    -- parent mode is changed
    if self.config.leave_when_mode_changed then
        local name = "submode_augroup"
        vim.api.nvim_create_augroup(name, {})
        vim.api.nvim_create_autocmd("ModeChanged", {
            group = name,
            pattern = "*",
            callback = function()
                self:leave()
            end
        })
    end
end

---Create a new submode.
---@param name string Name of this submode.
---@param info SubmodeInfo Infomation of this submode.
---@param ...  SubmodeMappingPre Mappings to register to this submode.
function M:create(name, info, ...)
    vim.validate{
        name = { name, "string" },
        info = { info, "table" }
    }

    if self:__detect_submode_confliction(name) then
        return
    end

    info = vim.tbl_extend("keep", info, {
        show_mode = true,
        enter = {},
        leave = {},
        enter_cb = function() end,
        leave_cb = function() end
    })
    self.submode_to_info[name] = info
    self.submode_to_mappings[name] = {}

    local listlized_enter = utils.listlize(info.enter)
    for _, enter in ipairs(listlized_enter) do
        vim.keymap.set(info.mode, enter, function()
            self:enter(name)
        end)
    end

    ---Register mappings.
    self:register(name, ...)
end

---Register mapping to submode.
---@param name string Name of target submode.
---@param ... SubmodeMappingPre Mappings to register.
function M:register(name, ...)
    vim.validate{
        name = { name, "string" },
    }

    self.submode_to_mappings[name] = self.submode_to_mappings[name] or {}
    for _, map_pre in ipairs{ ... } do
        local maps = convert_map_pre_to_maps(map_pre)
        for lhs, element in pairs(maps) do
            -- If rhs is function, call rhs with lhs.
            -- Also, I need add 'return' because
            -- returned string will be used if opts.expr is true.
            local actual_rhs = element.rhs
            if type(element.rhs) == "function" then
                actual_rhs = function() return element.rhs(lhs) end
            end
            element.opts = element.opts or {}

            if self:__detect_mapping_confliction(name, lhs) then
                return
            end
            self.submode_to_mappings[name][lhs] = {
                rhs  = actual_rhs,
                opts = element.opts
            }
        end
    end
end

---Return current submode, or nil if not in submode
---or submode's parent is not same as current mode.
---@return string | nil
function M:mode()
    if self.current_mode == "" then
        return nil
    end

    local curr = self.current_mode
    local info = self.submode_to_info[curr]
    local parent_is_same = mode:is_parent_same(self, curr)
    if parent_is_same and info.show_mode then
        return self.current_mode
    else
        return nil
    end
end

---Enter the submode.
---@param name string Name of submode to enter.
function M:enter(name)
    vim.validate{
        name = { name, "string" }
    }

    -- Validate given submode's name.
    local info = self.submode_to_info[name]
    assert(info ~= nil, ("No such submode exist: %s"):format(name))

    -- Validate that current mode and submode's parent mode is same
    local parent_is_same = mode:is_parent_same(self, name)
    if not parent_is_same then
        return
    end

    -- If in another submode, leave from the submode
    if self.current_mode ~= "" then
        self:leave()
    end

    -- Create snapshot
    self.snapshot:create(info.mode)

    -- Register mappings
    for lhs, map in pairs(self.submode_to_mappings[name] or {}) do
        vim.keymap.set(info.mode, lhs, map.rhs, map.opts)
    end

    -- Register leave keys to all buffers
    local listlized_leave = utils.listlize(self.submode_to_info[name].leave)
    for _, buf in ipairs(utils.get_list_bufs()) do
        table.insert(self.leave_bufs, buf)
        for _, leave in ipairs(listlized_leave) do
            vim.api.nvim_buf_set_keymap(buf, info.mode, leave, "", {
                callback = function()
                    self:leave()
                end
            })
        end
    end

    self.current_mode = name

    if self.submode_to_info[name].enter_cb then
        self.submode_to_info[name].enter_cb()
    end
end

---Leave from current submode.
function M:leave()
    if self.current_mode == "" then
        return
    end

    local name = self.current_mode
    local info = self.submode_to_info[name]

    -- Delete leave keys from all buffers
    local listlized_leave = utils.listlize(info.leave)
    for _, leave in ipairs(listlized_leave) do
        for _, buf in ipairs(self.leave_bufs) do
            if vim.api.nvim_buf_is_valid(buf) then
                vim.api.nvim_buf_del_keymap(buf, info.mode, leave)
            end
        end
    end
    self.leave_bufs = {}

    -- Delete mappings
    for lhs, _ in pairs(self.submode_to_mappings[self.current_mode] or {}) do
        vim.keymap.del(info.mode, lhs)
    end

    -- Restore previous keymaps from created snapshot
    self.snapshot:restore(info.mode)

    self.current_mode = ""

    if self.submode_to_info[name].leave_cb then
        self.submode_to_info[name].leave_cb()
    end
end

return M
