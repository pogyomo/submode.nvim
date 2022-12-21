local M = {}

---Take value-function paired map, then call a function
---associated to target. If not exist, call default.
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

---Convert a value to list which maybe list.
---@generic T
---@param target T | T[]
---@return T[]
function M.listlize(target)
    return type(target) == "table" and target or { target }
end

return M
