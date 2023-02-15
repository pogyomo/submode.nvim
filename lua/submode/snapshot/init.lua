local keymap = require("submode.snapshot.keymap")

---@class SnapshotManager
---@field mode_to_snapshot table<ShortenMode, Snapshot>

---@class Snapshot
---@field global KeymapInfo[]
---@field buffer table<integer, KeymapInfo[]>

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
    local bufs = {}
    for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
        for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tab)) do
            table.insert(bufs, vim.api.nvim_win_get_buf(win))
        end
    end
    bufs = remove_duplication(bufs)

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

    for _, map in ipairs(snapshot.global) do
        vim.api.nvim_set_keymap(mode, map.lhs, map.rhs, map.opts)
    end
    for buf, maps in ipairs(snapshot.buffer) do
        for _, map in ipairs(maps) do
            vim.api.nvim_buf_set_keymap(buf, mode, map.lhs, map.rhs, map.opts)
        end
    end
end

return M
