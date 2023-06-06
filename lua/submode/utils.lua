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

---Get all buffers.
---@return integer[]
function M.get_list_bufs()
    ---Remove duplicated item from given list.
    ---@generic T
    ---@param list T[]
    ---@return T[]
    local function remove_duplication(list)
        local hashmap = {}
        for _, value in ipairs(list) do
            hashmap[value] = value
        end
        return vim.tbl_values(hashmap)
    end

    local bufs = {}
    for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
        for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tab)) do
            table.insert(bufs, vim.api.nvim_win_get_buf(win))
        end
    end
    return remove_duplication(bufs)
end

return M
