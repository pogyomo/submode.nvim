local utils = require("submode.utils")
local mode  = require("submode.mode")
local snapshot = require("submode.snapshot")

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
                return vim.list_contains({
                    "error", "keep", "override"
                }, s)
            end,
            "error, keep or override"
        },
        when_submode_exist = {
            config.when_submode_exist,
            function(s)
                return vim.list_contains({
                    "error", "keep", "override"
                }, s)
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
        -- Use cloned default value to prevent that default value is changed.
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
        local err_msg = "Mapping confliction detected in %s: %s is already exist."
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

    -- Initialize internal state to prevent error when setup is called
    -- more than once.
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

    ---@type SubmodeInfo
    info = vim.tbl_extend("keep", info, {
        show_mode = true,
        enter = {},
        leave = {},
        enter_cb = function() end,
        leave_cb = function() end
    })
    self.submode_to_info[name] = info
    self.submode_to_mappings[name] = {}

    local listlized_enter = utils.listlize(info.enter) --[=[@as string[]]=]
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
        if type(info.mode_name) == "function" then
            return info.mode_name()
        elseif type(info.mode_name) == "string" then
            return info.mode_name --[[@as string]]
        else
            return self.current_mode
        end
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

    -- Register leave keys to global and all buffers
    self.leave_bufs = utils.get_list_bufs()
    for _, leave in ipairs(utils.listlize(info.leave) --[=[@as string[]]=]) do
        vim.api.nvim_set_keymap(info.mode, leave, "", {
            callback = function()
                self:leave()
            end
        })
        for _, buf in ipairs(utils.get_list_bufs()) do
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

    -- Delete leave keys from global and all buffers
    for _, leave in ipairs(utils.listlize(info.leave) --[=[@as string[]]=]) do
        vim.api.nvim_del_keymap(info.mode, leave)
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
