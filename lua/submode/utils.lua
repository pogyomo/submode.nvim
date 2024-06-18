local M = {}

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
