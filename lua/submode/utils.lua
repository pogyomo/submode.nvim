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

---Whether the target is in lists.
---@generic T
---@param target T Target value.
---@param lists T[] List for check.
---@return boolean True if target is in lists.
function M.is_one_of_them(target, lists)
    for _, value in ipairs(lists) do
        if target == value then
            return true
        end
    end
    return false
end

return M
