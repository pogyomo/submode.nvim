local utils = require("submode.utils")

---@return string
local function mode()
    -- TODO: Replace vim.fn.mode with vim.api.nvim_get_mode
    --       if the replacement doesn't change old behavior
    return vim.fn.mode(1) --[[@as string]]
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
function M:is_parent_same(submode, name)
    local parent = submode.submode_to_info[name].mode
    return utils.match(parent, {
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
        ["!"] = function()
            return self.is_insert_mode() or self.is_cmdline_mode()
        end,
        [""]  = function()
            return self.is_normal_mode()
                or self.is_visual_mode()
                or self.is_o_pending_mode()
        end
    }, function()
        error(("Parent of the submode %s is invalid: %s"):format(name, parent))
    end)
end

return M
