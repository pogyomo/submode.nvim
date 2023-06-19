---Prefix of map command or "!" for :map!, or "" for :map.
---Same as the mode nvim[_buf]_set_keymap accept.
---@alias ShortenMode "n" | "v" | "x" | "s" | "o" | "i" | "l" | "c" | "t" | "!" | ""

---@class KeymapInfo
---@field lhs  string
---@field rhs  string Empty if opts.callback exist.
---@field opts KeymapOpts

---@class KeymapOpts
---@field silent   boolean?
---@field noremap  boolean?
---@field script   boolean?
---@field expr     boolean?
---@field nowait   boolean?
---@field desc     string?
---@field callback function?
---@field replace_keycodes boolean?

---@param mode ShortenMode
---@param buf  integer? Buffer handle or 0 for current buffer, or nil for global.
---@return KeymapInfo
local function get_keymap(mode, buf)
    vim.validate{
        mode = {
            mode,
            function(s)
                return vim.list_contains({
                    "n", "v", "x", "s", "o", "i", "c", "t", "!", ""
                }, s)
            end,
            "n, v, x, s, o, i, c, t, ! or ''"
        },
        buf = { buf, { "number", "nil" } }
    }

    local getter = function(m)
        if buf then
            return vim.api.nvim_buf_get_keymap(buf, m)
        else
            return vim.api.nvim_get_keymap(m)
        end
    end

    -- NOTE: nvim_[buf_]get_keymap doesn't accept "!" and "".
    local maps
    if mode == "!" then
        maps = vim.tbl_filter(function(map)
            return map.mode == "!"
        end, getter("i"))
    elseif mode == "" then
        maps = vim.tbl_filter(function(map)
            return map.mode == " "
        end, getter("n"))
    else
        maps = getter(mode)
    end

    local ret = {}
    for _, map in ipairs(maps) do
        table.insert(ret, {
            lhs = map.lhs,
            rhs = map.rhs or "",
            opts = {
                silent   = map.silent == 1,
                noremap  = map.noremap == 1,
                script   = map.script == 1,
                expr     = map.expr == 1,
                nowait   = map.nowait == 1,
                desc     = map.desc,
                callback = map.callback,
                replace_keycodes = map.replace_keycodes and map.replace_keycodes == 1
            }
        })
    end
    return ret
end

local M = {}

---Get all global keymaps associated with given mode.
---@param mode ShortenMode
---@return KeymapInfo[]
function M.get_global_keymap(mode)
    return get_keymap(mode, nil)
end

---Get all buffer-local keymaps associated with given mode.
---@param mode ShortenMode
---@param buf  integer
---@return KeymapInfo[]
function M.get_buffer_keymap(buf, mode)
    return get_keymap(mode, buf)
end

return M
