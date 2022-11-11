local utils = require("submode.utils")

---@class Submode
---
---@field current_mode string
---Represent current mode, or empty string if not in submode.
---
---@field submode_to_info table<string, SubmodeInfo>
---Infomation of the submode
---
---@field submode_to_mappings table<string, SubmodeMapping[]>
---Mappings of the submode
---
---@field submode_to_map_escape table<string, MappingInfo[]>
---Mappings that will be saved while in the submode

---@class SubmodeInfo
---
---@field mode string
---@field enter string | string[]
---@field leave string | string[]

---@class SubmodeMapping
---
---@field lhs string
---@field rhs string | function
---@field opts? table

---@class SubmodeSetupConfig
---
---@field leave_when_mode_changed boolean
---Leave from submode when parent mode is changed

---@type Submode
---@diagnostic disable-next-line
local M = {
    current_mode = "",
    submode_to_info = {},
    submode_to_mappings = {},
    submode_to_map_escape = {},
}

---Initialize submode.nvim
---
---@param config? SubmodeSetupConfig
function M:setup(config)
    config = config or {}
    if config.leave_when_mode_changed == nil then
        config.leave_when_mode_changed = true
    end

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

---Create a new submode
---
---@param name string
---Name of this submode
---
---@param info SubmodeInfo
---Infomation of this submode
function M:create(name, info)
    vim.validate{
        name = { name, "string" },
        info = { info, "table" },
    }

    self.submode_to_info[name] = info

    utils.match(type(info.enter), {
        ["string"] = function()
            vim.keymap.set(info.mode, info.enter, function() self:enter(name) end)
        end,
        ["table"] = function()
            for _, enter in pairs(info.enter) do
                vim.keymap.set(info.mode, enter, function() self:enter(name) end)
            end
        end
    }, function()
        error("SubmodeInfo.enter must be string or string[]: got " .. type(info.enter))
    end)

    -- NOTE: To register leave key as a mapping of this submode,
    --       I prevent key confliction (e.g. Register <ESC> as leave key when parent is insert mode)
    utils.match(type(info.leave), {
        ["string"] = function()
            self:register(name, {
                lhs = info.leave,
                rhs = function() self:leave() end,
            })
        end,
        ["table"] = function()
            for _, leave in pairs(info.leave) do
                self:register(name, {
                    lhs = leave,
                    rhs = function() self:leave() end,
                })
            end
        end
    }, function()
    end)
end

---Register mapping to submode
---
---@param name string
---Name of target submode
---
---@param map SubmodeMapping
---Mapping to register
function M:register(name, map)
    vim.validate{
        name = { name, "string" },
        map = { map, "table" },
    }

    self.submode_to_mappings[name] = self.submode_to_mappings[name] or {}
    map.opts = map.opts or {}
    table.insert(self.submode_to_mappings[name], map)
end

---Return current submode, or nil if not in submode
---or submode's parent is not same as current mode
---
---@return string | nil
function M:mode()
    if self.current_mode == "" then
        return nil
    end

    local parent_is_same = utils:is_parent_same(self, self.current_mode)
    if parent_is_same then
        return self.current_mode
    else
        return nil
    end
end

---Enter the submode
---
---@param name string
---Name of submode to enter
function M:enter(name)
    vim.validate{
        name = { name, "string" },
    }

    -- Validate that current mode and submode's parent mode is same
    local parent_is_same = utils:is_parent_same(self, name)
    if not parent_is_same then
        return
    end

    -- If in another submode, leave from the submode
    if self.current_mode ~= "" then
        self:leave()
    end

    -- Register mappings
    local parent = self.submode_to_info[name].mode
    self.submode_to_map_escape[name] = {}
    for _, map in pairs(self.submode_to_mappings[name] or {}) do
        self.submode_to_map_escape[name] = utils.save(parent, map.lhs, self.submode_to_map_escape[name])
        vim.keymap.set(parent, map.lhs, map.rhs, map.opts)
    end

    self.current_mode = name
end

---Leave from current submode
function M:leave()
    if self.current_mode == "" then
        return
    end

    -- Delete mappings
    local parent = self.submode_to_info[self.current_mode].mode
    for _, map in pairs(self.submode_to_mappings[self.current_mode] or {}) do
        vim.keymap.del(parent, map.lhs)
    end

    utils.restore(self.submode_to_map_escape[self.current_mode])

    self.current_mode = ""
end

return M
