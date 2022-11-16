---@class MappingSaver
---
---@field info_list MappingInfo[]
---Infomation of preserved mappings

---@class MappingInfo
---
---@field mode string
---Name of target mode
---
---@field dict table
---Dictionary that maparg returns

---@class MappingSaver
local M = {}

---Create new saver
function M:new()
    return setmetatable({
        info_list = {},
    }, {
        __index = self,
    })
end

---Save current mapping using given info
---
---@param mode string
---Name of target mode
---
---@param name string
---Lhs of target keymap
function M:save(mode, name)
    local dict = vim.fn.maparg(name, mode, false, true)
    if next(dict) ~= nil then
        table.insert(self.info_list, { mode = mode, dict = dict })
    end
end

---Restore previous mapping.
function M:restore()
    for _, info in pairs(self.info_list) do
        vim.fn.mapset(info.mode, false, info.dict)
    end
    self.info_list = {}
end

return M
