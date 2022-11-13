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

---Take value-function paired map, then call a function
---associated to target. If not exist, call default.
---Unlike 'match', this doesn't return value.
---@generic T
---@param target T
---@param map table<T, function>
---@param default function
function M.switch(target, map, default)
    local func = map[target]
    if func == nil then
        default()
    else
        func()
    end
end

return M
