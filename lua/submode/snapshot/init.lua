local keymap = require("submode.snapshot.keymap")
local utils  = require("submode.utils")

---@class SnapshotManager
---@field mode_to_snapshot table<ShortenMode, Snapshot>

---@class Snapshot
---@field global KeymapInfo[]
---@field buffer table<integer, KeymapInfo[]>

---@class SnapshotManager
local M = {}

---@return SnapshotManager
function M:new()
    return setmetatable({
        mode_to_snapshot = {}
    }, {
        __index = self
    })
end

---Create a snapshot of given mode.
---@param mode ShortenMode
function M:create(mode)
    local bufs = utils.get_list_bufs()

    self.mode_to_snapshot[mode] = {}
    local snapshot = self.mode_to_snapshot[mode]
    snapshot.global = keymap.get_global_keymap(mode)
    snapshot.buffer = {}
    for _, buf in ipairs(bufs) do
        snapshot.buffer[buf] = keymap.get_buffer_keymap(buf, mode)
    end
end

---Restore mappings from previously created snapshot of given mode.
---If there is no snapshot, nothing happen.
---@param mode ShortenMode
function M:restore(mode)
    local snapshot = self.mode_to_snapshot[mode]
    if not snapshot then
        return
    end

    -- Restore global keymaps.
    for _, map in ipairs(snapshot.global) do
        vim.api.nvim_set_keymap(mode, map.lhs, map.rhs, map.opts)
    end

    -- Restore buffer-local keymaps.
    -- NOTE: I use pairs instead of ipairs because buffer handle is not continuous.
    for buf, maps in pairs(snapshot.buffer) do
        for _, map in ipairs(maps) do
            vim.api.nvim_buf_set_keymap(buf, mode, map.lhs, map.rhs, map.opts)
        end
    end
end

return M
