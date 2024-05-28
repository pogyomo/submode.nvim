local M = {}

---Take value-function paired map, then call a function
---associated with target. If not exist, call default.
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

---Convert a value which maybe list to list.
---@generic T
---@param target T | T[]
---@return T[]
function M.listlize(target)
    return type(target) == "table" and target or { target }
end

---Get all buffers.
---@return integer[]
function M.get_list_bufs()
    -- TODO: Should I remove unloaded buffers?
    return vim.api.nvim_list_bufs()
end

return M
