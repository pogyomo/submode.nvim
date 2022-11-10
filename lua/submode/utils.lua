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

---@return boolean
---True, or false if not in normal mode
function M.is_normal_mode()
    local pat1 = string.find(vim.fn.mode(1), "^n") ~= nil
    local pat2 = string.find(vim.fn.mode(1), "^ni.*") ~= nil
    local pat3 = string.find(vim.fn.mode(1), "^nt.*") ~= nil
    return pat1 or pat2 or pat3
end

---@return boolean
---True, or false if not in visual mode
function M.is_visual_mode()
    local pat1 = string.find(vim.fn.mode(1), "^v.*") ~= nil
    local pat2 = string.find(vim.fn.mode(1), "^V.*") ~= nil
    local pat3 = string.find(vim.fn.mode(1), "^\x16.*") ~= nil
    return pat1 or pat2 or pat3
end

---@return boolean
---True, or false if not in operator-pending mode
function M.is_o_pending_mode()
    return string.find(vim.fn.mode(1), "^no.*") ~= nil
end

---@return boolean
---True, or false if not in insert mode
function M.is_insert_mode()
    return string.find(vim.fn.mode(1), "^i.*") ~= nil
end

---@return boolean
---True, or false if not in cmdline mode
function M.is_cmdline_mode()
    return string.find(vim.fn.mode(1), "^c.*") ~= nil
end

---@return boolean
---True, or false if not in select mode
function M.is_select_mode()
    local pat1 = string.find(vim.fn.mode(1), "^s") ~= nil
    local pat2 = string.find(vim.fn.mode(1), "^S") ~= nil
    local pat3 = string.find(vim.fn.mode(1), "^\x13") ~= nil
    return pat1 or pat2 or pat3
end

---@return boolean
---True, or false if not in select mode
function M.is_terminal_mode()
    return string.find(vim.fn.mode(1), "^t") ~= nil
end

return M
