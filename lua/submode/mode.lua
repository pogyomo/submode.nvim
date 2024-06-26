local utils = require("submode.utils")

---Returns current mode
---@return string
local function mode()
    return vim.api.nvim_get_mode().mode
end

---Returns a function which returns true if any of function in `preds` returns true.
---@param preds (fun(): boolean)[]
---@return fun(): boolean
local function fany(preds)
    return function()
        return vim.iter(preds):any(function(pred)
            return pred()
        end)
    end
end

local M = {}

---@return boolean # False if not in normal mode.
function M.is_normal_mode()
    local pat1 = string.find(mode(), "^n") ~= nil
    local pat2 = string.find(mode(), "^ni.*") ~= nil
    local pat3 = string.find(mode(), "^nt.*") ~= nil
    return pat1 or pat2 or pat3
end

---@return boolean # False if not in visual mode.
function M.is_visual_mode()
    local pat1 = string.find(mode(), "^v.*") ~= nil
    local pat2 = string.find(mode(), "^V.*") ~= nil
    local pat3 = string.find(mode(), "^\x16.*") ~= nil
    return pat1 or pat2 or pat3
end

---@return boolean # False if not in operator-pending mode.
function M.is_o_pending_mode()
    return string.find(mode(), "^no.*") ~= nil
end

---@return boolean # False if not in insert mode.
function M.is_insert_mode()
    return string.find(mode(), "^i.*") ~= nil
end

---@return boolean # False if not in cmdline mode.
function M.is_cmdline_mode()
    return string.find(mode(), "^c.*") ~= nil
end

---@return boolean # False if not in select mode.
function M.is_select_mode()
    local pat1 = string.find(mode(), "^s") ~= nil
    local pat2 = string.find(mode(), "^S") ~= nil
    local pat3 = string.find(mode(), "^\x13") ~= nil
    return pat1 or pat2 or pat3
end

---@return boolean # False if not in select mode.
function M.is_terminal_mode()
    return string.find(mode(), "^t") ~= nil
end

---Returns true if current mode is expected mode.
---@param expect ShortenMode shorten mode name.
---@return boolean
function M.check_mode(expect)
    local checkers = {
        ["n"] = M.is_normal_mode,
        ["v"] = fany { M.is_visual_mode, M.is_select_mode },
        ["o"] = M.is_o_pending_mode,
        ["i"] = M.is_insert_mode,
        ["c"] = M.is_cmdline_mode,
        ["s"] = M.is_select_mode,
        ["x"] = M.is_visual_mode,
        -- TODO: Support 'l' as parent mode
        ["l"] = function()
            vim.notify("submode for `l` is not implemented yet", vim.log.levels.WARN, {
                title = "submode.nvim",
            })
            return false
        end,
        ["t"] = M.is_terminal_mode,
        ["!"] = fany { M.is_insert_mode, M.is_cmdline_mode },
        [""] = fany { M.is_normal_mode, M.is_visual_mode, M.is_o_pending_mode },
    }
    return assert(checkers[expect], string.format("invalid mode `%s`", expect))()
end

return M
