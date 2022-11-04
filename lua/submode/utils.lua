---@class MappingInfo
---@field mode string
---@field dict table

local M = {}

---Add current mapping to given array and return it
---@param mode string
---@param name string
---@param info_list MappingInfo[]
---@return MappingInfo[]
function M.save(mode, name, info_list)
    local dict = vim.fn.maparg(name, mode, false, true)
    if next(dict) ~= nil then
        table.insert(info_list, { mode = mode, dict = dict })
    end
    return info_list
end

---Restore previous mapping using given array
---@param info_list MappingInfo[]
function M.restore(info_list)
    for _, info in pairs(info_list) do
        vim.fn.mapset(info.mode, false, info.dict)
    end
end

---Take value-function paired map, then call a function
---associated to target. If not exist, return default.
---@generic T
---@generic U
---@param target T
---@param map table<T, fun(): U>
---@param default fun(): U
function M.match(target, map, default)
    local func = map[target]
    if func == nil then
        return default()
    else
        return func()
    end
end

return M
