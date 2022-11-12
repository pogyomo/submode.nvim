local M = {}

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

---@param submode Submode
---@param name string
---Name of submode
---Whether current mode and given submode's parent is same or not
function M:is_parent_same(submode, name)
    local parent = submode.submode_to_info[name].mode
    return self.match(parent, {
        ["n"] = self.is_normal_mode,
        ["v"] = function()
            return self.is_visual_mode() or self.is_select_mode()
        end,
        ["o"] = self.is_o_pending_mode,
        ["i"] = self.is_insert_mode,
        ["c"] = self.is_cmdline_mode,
        ["s"] = self.is_select_mode,
        ["x"] = self.is_visual_mode,
        -- TODO: Support 'l' as parent mode
        ["l"] = function()
            error("Currently submode.nvim dosen't accept 'l' as parent mode")
        end,
        ["t"] = self.is_terminal_mode,
        [""]  = function()
            return self.is_normal_mode() or self.is_visual_mode() or self.is_o_pending_mode()
        end
    }, function()
        error(string.format("Parent of the submode %s is invalid: %s", name, parent))
    end)
end

return M
