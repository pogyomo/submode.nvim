local utils = require("submode.utils")
local saver = require("submode.saver")
local mode  = require("submode.mode")

---@class Submode
---@field current_mode string Represent current mode, or empty string if not in submode.
---@field submode_to_info table<string, SubmodeInfo> Infomation of the submode.
---@field submode_to_mappings table<string, SubmodeMappings> Mappings of the submode.
---@field mapping_saver MappingSaver Mapping saver.
---@field config SubmodeSetupConfig Config of this plugin.

---@class SubmodeInfo
---@field mode string
---@field enter? string | string[]
---@field leave? string | string[]

---Combination of lhs and element.
---@alias SubmodeMappings table<string, SubmodeMappingElement>

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
---@field when_mapping_conflict "error" | "override" Behavior when mapping conflict.

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
        when_mapping_conflict = {
            config.when_mapping_conflict,
            function(s)
                return s == "error" or s == "override"
            end,
            "error or override"
        }
    }
end

---Default status of this plugin
---@class Submode
local default_state = {
    current_mode = "",
    submode_to_info = {},
    submode_to_mappings = {},
    mapping_saver = saver:new(),
    config = {
        leave_when_mode_changed = false,
        when_mapping_conflict = "error"
    }
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

---Detect mapping confliction.
---@param name string Name of submode to check.
---@param lhs string Lhs of the mapping.
function M:__detect_mapping_confliction(name, lhs)
    if not self.submode_to_mappings[name][lhs] then
        return
    end
    if self.config.when_mapping_conflict == "error" then
        local err_msg = "Mapping confliction detected in %s: %s is already defined."
        error(err_msg:format(name, lhs))
    end
end

---Initialize submode.nvim
---@param config? SubmodeSetupConfig
function M:setup(config)
    vim.validate{
        config = { config, { "table", "nil" } }
    }

    -- NOTE: I initialize internal state because if the settings of this plugin
    --       is reloaded (i.e. PackerCompile) and when_mapping_conflict is error,
    --       error occure. This happen because create or register called although
    --       its settings is already exist. So this prevent the error.
    self:__initialize_state()

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

    self.submode_to_info[name] = info

    local listlized_enter = utils.listlize(info.enter or {})
    for _, enter in ipairs(listlized_enter) do
        vim.keymap.set(info.mode, enter, function() self:enter(name) end)
    end

    -- NOTE: To register leave key as a mapping of this submode,
    --       I prevent key confliction.
    --       e.g. Register <ESC> as leave key when parent is insert mode
    local listlized_leave = utils.listlize(info.leave or {})
    self:register(name, {
        lhs = listlized_leave,
        rhs = function() self:leave() end
    })

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

            self:__detect_mapping_confliction(name, lhs)
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

    local parent_is_same = mode:is_parent_same(self, self.current_mode)
    if parent_is_same then
        return self.current_mode
    else
        return nil
    end
end

---Enter the submode.
---@param name string Name of submode to enter.
function M:enter(name)
    vim.validate{
        name = { name, "string" },
    }

    -- Validate that current mode and submode's parent mode is same
    local parent_is_same = mode:is_parent_same(self, name)
    if not parent_is_same then
        return
    end

    -- If in another submode, leave from the submode
    if self.current_mode ~= "" then
        self:leave()
    end

    -- Register mappings
    local parent = self.submode_to_info[name].mode
    for lhs, map in pairs(self.submode_to_mappings[name] or {}) do
        self.mapping_saver:save(parent, lhs)
        vim.keymap.set(parent, lhs, map.rhs, map.opts)
    end

    self.current_mode = name
end

---Leave from current submode.
function M:leave()
    if self.current_mode == "" then
        return
    end

    -- Delete mappings
    local parent = self.submode_to_info[self.current_mode].mode
    for lhs, _ in pairs(self.submode_to_mappings[self.current_mode] or {}) do
        vim.keymap.del(parent, lhs)
    end

    self.mapping_saver:restore()

    self.current_mode = ""
end

return M
