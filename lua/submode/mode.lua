local utils = require("submode.utils")

---Returns current mode
---@return string
local function mode()
    return vim.api.nvim_get_mode().mode
end

local M = {}

---@return boolean # True, or false if not in normal mode.
function M.is_normal_mode()
    local pat1 = string.find(mode(), "^n") ~= nil
    local pat2 = string.find(mode(), "^ni.*") ~= nil
    local pat3 = string.find(mode(), "^nt.*") ~= nil
    return pat1 or pat2 or pat3
end

---@return boolean # True, or false if not in visual mode.
function M.is_visual_mode()
    local pat1 = string.find(mode(), "^v.*") ~= nil
    local pat2 = string.find(mode(), "^V.*") ~= nil
    local pat3 = string.find(mode(), "^\x16.*") ~= nil
    return pat1 or pat2 or pat3
end

---@return boolean # True, or false if not in operator-pending mode.
function M.is_o_pending_mode()
    return string.find(mode(), "^no.*") ~= nil
end

---@return boolean # True, or false if not in insert mode.
function M.is_insert_mode()
    return string.find(mode(), "^i.*") ~= nil
end

---@return boolean # True, or false if not in cmdline mode.
function M.is_cmdline_mode()
    return string.find(mode(), "^c.*") ~= nil
end

---@return boolean # True, or false if not in select mode.
function M.is_select_mode()
    local pat1 = string.find(mode(), "^s") ~= nil
    local pat2 = string.find(mode(), "^S") ~= nil
    local pat3 = string.find(mode(), "^\x13") ~= nil
    return pat1 or pat2 or pat3
end

---@return boolean # True, or false if not in select mode.
function M.is_terminal_mode()
    return string.find(mode(), "^t") ~= nil
end

---Whether current mode and given submode's parent is same or not.
---@param submode Submode
---@param name string Name of submode.
function M.is_parent_same(submode, name)
    local parent = submode.state.submode_to_info[name].mode
    return utils.match(parent, {
        ["n"] = M.is_normal_mode,
        ["v"] = function()
            return M.is_visual_mode() or M.is_select_mode()
        end,
        ["o"] = M.is_o_pending_mode,
        ["i"] = M.is_insert_mode,
        ["c"] = M.is_cmdline_mode,
        ["s"] = M.is_select_mode,
        ["x"] = M.is_visual_mode,
        -- TODO: Support 'l' as parent mode
        ["l"] = function()
            error("Currently submode.nvim dosen't accept 'l' as parent mode")
        end,
        ["t"] = M.is_terminal_mode,
        ["!"] = function()
            return M.is_insert_mode() or M.is_cmdline_mode()
        end,
        [""] = function()
            return M.is_normal_mode() or M.is_visual_mode() or M.is_o_pending_mode()
        end,
    }, function()
        error(("Parent of the submode %s is invalid: %s"):format(name, parent))
    end)
end

return M
