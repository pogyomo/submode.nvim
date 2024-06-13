local utils = require("submode.utils")
local mode = require("submode.mode")
local snapshot = require("submode.snapshot")

---Validate config.
---@param config SubmodeSetupConfig Config to validate.
local function validate_config(config)
    vim.validate {
        leave_when_mode_changed = {
            config.leave_when_mode_changed,
            "boolean",
        },
        when_submode_exist = {
            config.when_submode_exist,
            function(s)
                return vim.list_contains({
                    "error",
                    "keep",
                    "override",
                }, s)
            end,
            "error, keep or override",
        },
    }
end

---Default state of this plugin
---@class SubmodeState
local default_state = {
    current_mode = "",
    submode_to_info = {},
    submode_to_user_mappings = {},
    submode_to_default_mappings = {},
    snapshot = snapshot:new(),
    leave_bufs = {},
}

---Default config of this plugin
---@class SubmodeSetupConfig
local default_config = {
    leave_when_mode_changed = false,
    when_submode_exist = "error",
}

---@class Submode
local M = {}

---Initialize this plugin's state.
---All mappings and config will be lost.
local function initialize_submode()
    M.state = vim.deepcopy(default_state)
    M.config = vim.deepcopy(default_config)
end

---Detect submode confliction.
---@param name string Name of submode.
---@return boolean # True if submode exist and when_submode_exist isn't override.
local function detect_submode_confliction(name)
    if M.config.when_submode_exist == "error" then
        if M.state.submode_to_info[name] then
            error(("Submode %s already exist."):format(name))
            return true
        end
        return false
    elseif M.config.when_submode_exist == "keep" then
        return M.state.submode_to_info[name] ~= nil
    else
        return false
    end
end

---Initialize submode.nvim
---@param config? SubmodeSetupConfig
function M.setup(config)
    if
        config and config.setup --[[@as Submode]]
    then
        vim.notify(
            "You are trying to call methods using `:`, which is the old way. Instead, use `.` instead.",
            vim.log.levels.ERROR,
            { title = "submode.nvim" }
        )
        return
    end

    vim.validate {
        config = { config, { "table", "nil" } },
    }

    -- Initialize internal state and config to prevent error when setup is called
    -- more than once.
    initialize_submode()

    -- Initialize config with given config.
    M.config = vim.tbl_extend("keep", config or {}, M.config)
    validate_config(M.config)

    -- Create autocommand to exit submode when
    -- parent mode is changed
    if M.config.leave_when_mode_changed then
        local name = "submode_augroup"
        vim.api.nvim_create_augroup(name, {})
        vim.api.nvim_create_autocmd("ModeChanged", {
            group = name,
            pattern = "*",
            callback = function()
                M.leave()
            end,
        })
    end
end

---Create a new submode.
---@param name string Name of this submode.
---@param info SubmodeInfo Infomation of this submode.
---@param ...  SubmodeDefaultMapping Default mappings for this submode.
function M.create(name, info, ...)
    local state = M.state

    vim.validate {
        name = { name, "string" },
        info = { info, "table" },
    }

    if detect_submode_confliction(name) then
        return
    end

    ---@type SubmodeInfo
    info = vim.tbl_extend("keep", info, {
        show_mode = true,
        enter = {},
        leave = {},
        enter_cb = function() end,
        leave_cb = function() end,
    })
    state.submode_to_info[name] = info
    state.submode_to_user_mappings[name] = {}
    state.submode_to_default_mappings[name] = {}

    local listlized_enter = utils.listlize(info.enter) --[=[@as string[]]=]
    for _, enter in ipairs(listlized_enter) do
        vim.keymap.set(info.mode, enter, function()
            M.enter(name)
        end)
    end

    ---Register mappings.
    for _, map in ipairs { ... } do
        M.state.submode_to_default_mappings[name][map.lhs] = {
            rhs = map.rhs,
            opts = map.opts,
        }
    end
end

---Register mapping to submode.
---@param name string Name of target submode.
function M.register(name, ...)
    vim.deprecate("submode.register", "submode.set", "3.0.0", "submode.nvim")

    for _, map in ipairs { ... } do
        for _, lhs in utils.listlize(map.lhs) do
            M.set(name, lhs, map.rhs, map.opts)
        end
    end
end

---Add a mapping to `name`. Same interface as `vim.keymap.set`
---@param name string Name of target submode.
---@param lhs string Lhs of mapping.
---@param rhs string | fun():string? Rhs of mapping. Can be function.
---@param opts? table Options of this mapping. Same as `opts` of `vim.keymap.set`.
function M.set(name, lhs, rhs, opts)
    vim.validate {
        name = { name, "string" },
        lhs = { lhs, "string" },
        rhs = { rhs, { "string", "function" } },
        opts = { opts, "table", true },
    }

    M.state.submode_to_user_mappings[name][lhs] = {
        rhs = rhs,
        opts = opts,
    }
end

---Delete a mapping from `name`. Same interface as `vim.keymap.del`.
---@param name string Name of target submode.
---@param lhs string Lhs of target keymap.
---@param opts? table Options for this deletion. Currently no option is available.
function M.del(name, lhs, opts)
    vim.validate {
        name = { name, "string" },
        lhs = { lhs, "string" },
        opts = { opts, "table", true },
    }

    M.state.submode_to_user_mappings[name][lhs] = nil
end

---Return current submode, or nil if not in submode
---or submode's parent is not same as current mode.
---@return string | nil
function M.mode()
    local state = M.state

    if state.current_mode == "" then
        return nil
    end

    local curr = state.current_mode
    local info = state.submode_to_info[curr]
    local parent_is_same = mode.is_parent_same(M, curr)
    if parent_is_same and info.show_mode then
        if type(info.mode_name) == "function" then
            return info.mode_name()
        elseif type(info.mode_name) == "string" then
            return info.mode_name --[[@as string]]
        else
            return state.current_mode
        end
    else
        return nil
    end
end

---Enter the submode.
---@param name string Name of submode to enter.
function M.enter(name)
    local state = M.state

    vim.validate {
        name = { name, "string" },
    }

    -- Validate given submode's name.
    local info = state.submode_to_info[name]
    assert(info ~= nil, ("No such submode exist: %s"):format(name))

    -- Validate that current mode and submode's parent mode is same
    local parent_is_same = mode.is_parent_same(M, name)
    if not parent_is_same then
        return
    end

    -- If in another submode, leave from the submode
    if state.current_mode ~= "" then
        M.leave()
    end

    -- Create snapshot
    state.snapshot:create(info.mode)

    -- Register default mappings
    for lhs, map in pairs(state.submode_to_default_mappings[name] or {}) do
        if not state.submode_to_user_mappings[name][lhs] then
            vim.keymap.set(info.mode, lhs, map.rhs, map.opts)
        end
    end

    -- Register user mappings
    for lhs, map in pairs(state.submode_to_user_mappings[name] or {}) do
        vim.keymap.set(info.mode, lhs, map.rhs, map.opts)
    end

    -- Register leave keys to global and all buffers
    state.leave_bufs = utils.get_list_bufs()
    for _, leave in
        ipairs(utils.listlize(info.leave) --[=[@as string[]]=])
    do
        vim.api.nvim_set_keymap(info.mode, leave, "", {
            callback = function()
                M.leave()
            end,
        })
        for _, buf in ipairs(utils.get_list_bufs()) do
            vim.api.nvim_buf_set_keymap(buf, info.mode, leave, "", {
                callback = function()
                    M.leave()
                end,
            })
        end
    end

    state.current_mode = name

    if state.submode_to_info[name].enter_cb then
        state.submode_to_info[name].enter_cb()
    end
end

---Leave from current submode.
function M.leave()
    local state = M.state

    if state.current_mode == "" then
        return
    end

    local name = state.current_mode
    local info = state.submode_to_info[name]

    -- Delete leave keys from global and all buffers
    for _, leave in
        ipairs(utils.listlize(info.leave) --[=[@as string[]]=])
    do
        vim.api.nvim_del_keymap(info.mode, leave)
        for _, buf in ipairs(state.leave_bufs) do
            if vim.api.nvim_buf_is_valid(buf) then
                vim.api.nvim_buf_del_keymap(buf, info.mode, leave)
            end
        end
    end
    state.leave_bufs = {}

    -- Delete user mappings
    for lhs, _ in pairs(state.submode_to_user_mappings[state.current_mode] or {}) do
        vim.keymap.del(info.mode, lhs)
    end

    -- Delete default mappings
    for lhs, _ in pairs(state.submode_to_default_mappings[state.current_mode] or {}) do
        if not state.submode_to_user_mappings[name][lhs] then
            vim.keymap.del(info.mode, lhs)
        end
    end

    -- Restore previous keymaps from created snapshot
    state.snapshot:restore(info.mode)

    state.current_mode = ""

    if state.submode_to_info[name].leave_cb then
        state.submode_to_info[name].leave_cb()
    end
end

return M
