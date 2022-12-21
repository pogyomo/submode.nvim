local utils = require("submode.utils")
local saver = require("submode.saver")
local mode  = require("submode.mode")

---@class Submode
---@field current_mode string Represent current mode, or empty string if not in submode.
---@field submode_to_info table<string, SubmodeInfo> Infomation of the submode.
---@field submode_to_mappings table<string, SubmodeMapping[]> Mappings of the submode.
---@field mapping_saver MappingSaver Mapping saver.

---@class SubmodeInfo
---@field mode string
---@field enter? string | string[]
---@field leave? string | string[]

---Mapping infomation which user pass.
---@class SubmodeMappingPre
---@field lhs string | string[]
---@field rhs string | fun(lha: string):string?
---@field opts? table

---Mapping infomation which this plugin use internally.
---@class SubmodeMapping
---@field lhs string
---@field rhs string | fun(lhs: string):string?
---@field opts? table

---@class SubmodeSetupConfig
---@field leave_when_mode_changed boolean Leave from submode when parent mode is changed.

---@class SubmodeSetupConfig
local default = {
    leave_when_mode_changed = false
}

---Convert SubmodeMappingPre to list of SubmodeMapping.
---This doesn't affect to map.rhs and map.opts.
---@param map SubmodeMappingPre
---@return SubmodeMapping[]
local function map_pre_normalize(map)
    local ret = {}
    local tablized_lhs = type(map.lhs) == "table" and map.lhs or { map.lhs }
    for _, lhs in ipairs(tablized_lhs --[=[@as string[]]=]) do
        table.insert(ret, {
            lhs  = lhs,
            rhs  = map.rhs,
            opts = map.opts or {}
        })
    end
    return ret
end

---@class Submode
local M = {
    current_mode = "",
    submode_to_info = {},
    submode_to_mappings = {},
    mapping_saver = saver:new(),
}

---Initialize submode.nvim
---@param config? SubmodeSetupConfig
function M:setup(config)
    config = vim.tbl_extend("keep", config or {}, default)

    -- Create autocommand to exit submode when
    -- parent mode is changed
    if config.leave_when_mode_changed then
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
        info = { info, "table" },
    }

    self.submode_to_info[name] = info

    utils.switch(type(info.enter), {
        ["string"] = function()
            vim.keymap.set(info.mode, info.enter, function() self:enter(name) end)
        end,
        ["table"] = function()
            for _, enter in pairs(info.enter --[=[@as string[]]=]) do
                vim.keymap.set(info.mode, enter, function() self:enter(name) end)
            end
        end
    })

    -- NOTE: To register leave key as a mapping of this submode,
    --       I prevent key confliction (e.g. Register <ESC> as leave key when parent is insert mode)
    utils.switch(type(info.leave), {
        ["string"] = function()
            self:register(name, {
                lhs = info.leave --[[@as string]],
                rhs = function() self:leave() end,
            })
        end,
        ["table"] = function()
            for _, leave in pairs(info.leave --[=[@as string[]]=]) do
                self:register(name, {
                    lhs = leave,
                    rhs = function() self:leave() end,
                })
            end
        end
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
        local normalized_maps = map_pre_normalize(map_pre)
        for _, map in ipairs(normalized_maps) do
            -- If rhs is function, call rhs with lhs.
            -- Also, I need add 'return' because
            -- returned string will be used if opts.expr is true.
            local actual_rhs = map.rhs
            if type(map.rhs) == "function" then
                actual_rhs = function() return map.rhs(map.lhs) end
            end
            table.insert(self.submode_to_mappings[name], {
                lhs  = map.lhs,
                rhs  = actual_rhs,
                opts = map.opts
            })
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
    for _, map in pairs(self.submode_to_mappings[name] or {}) do
        self.mapping_saver:save(parent, map.lhs)
        vim.keymap.set(parent, map.lhs, map.rhs, map.opts)
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
    for _, map in pairs(self.submode_to_mappings[self.current_mode] or {}) do
        vim.keymap.del(parent, map.lhs)
    end

    self.mapping_saver:restore()

    self.current_mode = ""
end

return M
