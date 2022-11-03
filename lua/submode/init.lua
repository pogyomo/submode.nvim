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
---@field enter string
---@field leave string

---@class SubmodeMapping
---
---@field lhs string
---@field rhs string | function
---@field opts? table

---@type Submode
---@diagnostic disable-next-line
submode = {
    current_mode = "",
    submode_to_info = {},
    submode_to_mappings = {},
    submode_to_map_escape = {},
}

---Create a new submode
---
---@param name string
---Name of this submode
---
---@param info SubmodeInfo
---Infomation of this submode
function submode:create(name, info)
    self.submode_to_info[name] = info

    vim.keymap.set(info.mode, info.enter, function() self:enter(name) end)
    ---- HACK: What happen if default movement of <ESC> was overwritten?
    --vim.keymap.set(info.mode, info.leave, function() self:leave()     end)

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
    self.submode_to_mappings[name] = self.submode_to_mappings[name] or {}
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

    -- Register mappings
    local parent = self.submode_to_info[name].mode
    self.submode_to_map_escape[name] = {}
    for _, map in pairs(self.submode_to_mappings[name] or {}) do
        self.submode_to_map_escape[name] = utils.save(parent, map.lhs, self.submode_to_map_escape[name])
        vim.keymap.set(parent, map.lhs, map.rhs, map.opts)
    end

    -- Register leave mapping
    local leave = self.submode_to_info[name].leave
    self.submode_to_map_escape[name] = utils.save(parent, leave, self.submode_to_map_escape[name])
    vim.keymap.set(parent, leave, function() self:leave() end)

    self.current_mode = name
end

---Leave from current submode
function submode:leave()
    if self.current_mode == "" then
        return
    end

    -- Delete mappings and leave mapping
    local parent = self.submode_to_info[self.current_mode].mode
    for _, map in pairs(self.submode_to_mappings[self.current_mode] or {}) do
        vim.keymap.del(parent, map.lhs)
    end
    vim.keymap.del(parent, self.submode_to_info[self.current_mode].leave)

    utils.restore(self.submode_to_map_escape[self.current_mode])

    self.current_mode = ""
end

return setmetatable({}, { __index = submode })
