local utils = require("submode.utils")

---@class Submode
---
---@field current_mode string
---Represent current mode, or empty string if not in submode.
---
---@field submode_to_parent table<string, string>
---Save parent mode of the submode
---
---@field submode_to_enter table<string, string>
---Save mapping to enter the submode
---
---@field submode_to_leave table<string, string>
---Save mapping to leave from the submode
---
---@field submode_to_mappings table<string, SubmodeMapping[]>
---Mappings of the submode
---
---@field submode_to_map_escape table<string, MappingInfo[]>
---Mappings that will be saved while in the submode

---@class SubmodeMapping
---
---@field lhs string
---@field rhs string | function
---@field opts? table

---@type Submode
---@diagnostic disable-next-line
submode = {
    current_mode = "",
    submode_to_parent = {},
    submode_to_enter = {},
    submode_to_leave = {},
    submode_to_mappings = {},
    submode_to_map_escape = {},
}

---Create a new submode
---
---@param name string
---Name of this submode
---
---@param mode string
---Parent of this submode
---
---@param enter string
---Mapping to enter this submode
---
---@param leave string
---Mapping to leave from this submode
function submode:create(name, mode, enter, leave)
    self.submode_to_parent[name] = mode
    self.submode_to_enter[name] = enter
    self.submode_to_leave[name] = leave

    vim.keymap.set(mode, enter, function() self:enter(name) end)
    vim.keymap.set(mode, leave, function() self:leave()     end)

    local auname = "submode_" .. name
    vim.api.nvim_create_augroup(auname, {})
    vim.api.nvim_create_autocmd("ModeChanged", {
        group = auname,
        pattern = "*",
        callback = function()
            self:leave()
        end
    })
end

---Register mapping to submode
---
---@param name string
---Name of target submode
---
---@param map SubmodeMapping
---Mapping to register
function submode:register(name, map)
    map.opts = map.opts or {}
    table.insert(self.submode_to_mappings[name], map)
end

---Return current mode, or nil if not in submode
---
---@return string | nil
function submode:mode()
    if self.current_mode == "" then
        return nil
    else
        return self.current_mode
    end
end

---Enter the submode
---
---@param name string
---Name of submode to enter
function submode:enter(name)
    if self.current_mode ~= "" then
        return
    end

    local parent = self.submode_to_parent[name]
    self.submode_to_map_escape[name] = {}
    for _, map in pairs(self.submode_to_mappings[name] or {}) do
        self.submode_to_map_escape[name] = utils.save(parent, map.lhs, self.submode_to_map_escape[name])
        vim.keymap.set(parent, map.lhs, map.rhs, map.opts)
    end

    self.current_mode = name
end

---Leave from current submode
function submode:leave()
    if self.current_mode == "" then
        return
    end

    for _, map in pairs(self.submode_to_mappings[self.current_mode] or {}) do
        vim.keymap.del(self.submode_to_parent[self.current_mode], map.lhs)
    end
    utils.restore(self.submode_to_map_escape[self.current_mode])

    self.current_mode = ""
end

return setmetatable({}, { __index = submode })
