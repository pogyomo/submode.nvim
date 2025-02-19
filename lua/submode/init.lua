local utils = require("submode.utils")
local mode = require("submode.mode")
local snapshot = require("submode.snapshot")
local validate = require("submode.validate").validate

---Default state of this plugin
---@class SubmodeState
local default_state = {
    current_mode = "",
    submode_to_opts = {},
    submode_to_user_mappings = {},
    submode_to_default_mappings = {},
    snapshot = snapshot:new(),
    leave_bufs = {},
}

---@class Submode
local M = {
    state = vim.deepcopy(default_state),
}

---Create a new submode.
---@param name string Name of this submode.
---@param opts SubmodeOpts Options of this submode.
---@param default? fun(register: SubmodeDefaultMappingRegister) Default mappings register
function M.create(name, opts, default)
    validate("name", name, "string")
    validate("opts", opts, "table")
    validate("default", default, "function", true)

    local state = M.state

    -- Judge to continue process by checking `override_behavior`.
    if state.submode_to_opts[name] then
        if state.submode_to_opts[name].override_behavior == "error" then
            error(string.format("submode `%s` already exists", name))
        elseif state.submode_to_opts[name].override_behavior == "keep" then
            return
        end
    end

    ---@type SubmodeOpts
    opts = vim.tbl_extend("keep", opts, {
        show_mode = true,
        enter = {},
        leave = {},
        hook = {
            on_enter = function() end,
            on_leave = function() end,
        },
        default = function() end,
        leave_when_mode_changed = false,
        override_behavior = "error",
    })
    state.submode_to_opts[name] = opts
    state.submode_to_user_mappings[name] = {}
    state.submode_to_default_mappings[name] = {}

    for _, enter in
        ipairs(utils.listlize(opts.enter) --[=[@as string[]]=])
    do
        vim.keymap.set(opts.mode, enter, function()
            M.enter(name)
        end)
    end

    if opts.leave_when_mode_changed then
        vim.api.nvim_create_autocmd("ModeChanged", {
            group = vim.api.nvim_create_augroup(string.format("submode-%s-augroup", name), {}),
            pattern = "*",
            callback = function()
                M.leave()
            end,
        })
    end

    ---@param lhs string
    ---@param rhs string | fun():string?
    ---@param opts_ vim.keymap.set.Opts?
    local register = function(lhs, rhs, opts_)
        validate("lhs", lhs, "string")
        validate("rhs", rhs, { "string", "function" })
        validate("opts", opts_, "table", true)

        M.state.submode_to_default_mappings[name][lhs] = {
            rhs = rhs,
            opts = opts_,
        }
    end
    opts.default(register)
    if default then
        vim.deprecate("callback to `submode.create`", "`opts`", "7.0.0", "submode.nvim", false)
        default(register)
    end
end

---Add a mapping to `name`. Same interface as `vim.keymap.set`.
---@param name string Name of target submode.
---@param lhs string Lhs of mapping.
---@param rhs string | fun():string? Rhs of mapping. Can be function.
---@param opts? vim.keymap.set.Opts Options of this mapping. Same as `opts` of `vim.keymap.set`.
function M.set(name, lhs, rhs, opts)
    validate("name", name, "string")
    validate("lhs", lhs, "string")
    validate("rhs", rhs, { "string", "function" })
    validate("opts", opts, "table", true)

    M.state.submode_to_user_mappings[name][lhs] = {
        rhs = rhs,
        opts = opts,
    }

    if M.state.current_mode == name then
        vim.keymap.set(M.state.submode_to_opts[name].mode, lhs, rhs, opts)
    end
end

---Delete a mapping from `name`. Same interface as `vim.keymap.del`.
---@param name string Name of target submode.
---@param lhs string Lhs of target keymap.
---@param opts? vim.keymap.del.Opts Options for this deletion. Same as `opts` in `vim.keymap.del`.
function M.del(name, lhs, opts)
    validate("name", name, "string")
    validate("lhs", lhs, "string")
    validate("opts", opts, "table", true)

    if not M.state.submode_to_user_mappings[name][lhs] then
        return
    end

    M.state.submode_to_user_mappings[name][lhs] = nil

    if M.state.current_mode == name then
        vim.keymap.del(M.state.submode_to_opts[name].mode, lhs, opts)
        if M.state.submode_to_default_mappings[name][lhs] then
            vim.keymap.set(
                M.state.submode_to_opts[name].mode,
                lhs,
                M.state.submode_to_default_mappings[name][lhs].rhs,
                M.state.submode_to_default_mappings[name][lhs].opts
            )
        end
    end
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
    local opts = state.submode_to_opts[curr]
    if mode.check_mode(opts.mode) and opts.show_mode then
        if type(opts.mode_name) == "function" then
            return opts.mode_name()
        elseif type(opts.mode_name) == "string" then
            return opts.mode_name --[[@as string]]
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
    validate("name", name, "string")

    local state = M.state
    local opts = state.submode_to_opts[name]

    -- Validate given submode's name.
    if not opts then
        error(string.format("submode `%s` doesn't exist", name))
    end

    -- Validate that current mode are expected mode.
    if not mode.check_mode(opts.mode) then
        return
    end

    vim.api.nvim_exec_autocmds("User", {
        pattern = "SubmodeEnterPre",
        modeline = false,
        data = {
            name = name,
        },
    })

    -- If in another submode, leave from the submode
    if state.current_mode ~= "" then
        M.leave()
    end

    -- Create snapshot
    state.snapshot:create(opts.mode)

    -- Register default mappings
    for lhs, element in pairs(state.submode_to_default_mappings[name] or {}) do
        if not state.submode_to_user_mappings[name][lhs] then
            vim.keymap.set(opts.mode, lhs, element.rhs, element.opts)
        end
    end

    -- Register user mappings
    for lhs, element in pairs(state.submode_to_user_mappings[name] or {}) do
        vim.keymap.set(opts.mode, lhs, element.rhs, element.opts)
    end

    -- Register leave keys to global and all buffers
    state.leave_bufs = utils.get_list_bufs()
    for _, leave in
        ipairs(utils.listlize(opts.leave) --[=[@as string[]]=])
    do
        vim.api.nvim_set_keymap(opts.mode, leave, "", {
            callback = function()
                M.leave()
            end,
        })
        for _, buf in ipairs(utils.get_list_bufs()) do
            vim.api.nvim_buf_set_keymap(buf, opts.mode, leave, "", {
                callback = function()
                    M.leave()
                end,
            })
        end
    end

    state.current_mode = name

    vim.api.nvim_exec_autocmds("User", {
        pattern = "SubmodeEnterPost",
        modeline = false,
        data = {
            name = name,
        },
    })
    opts.hook.on_enter()
end

---Leave from current submode.
function M.leave()
    local state = M.state
    local name = state.current_mode
    local opts = state.submode_to_opts[name]

    if state.current_mode == "" then
        return
    end

    vim.api.nvim_exec_autocmds("User", {
        pattern = "SubmodeLeavePre",
        modeline = false,
        data = {
            name = name,
        },
    })

    -- Delete leave keys from global and all buffers
    for _, leave in
        ipairs(utils.listlize(opts.leave) --[=[@as string[]]=])
    do
        vim.api.nvim_del_keymap(opts.mode, leave)
        for _, buf in ipairs(state.leave_bufs) do
            if vim.api.nvim_buf_is_valid(buf) then
                vim.api.nvim_buf_del_keymap(buf, opts.mode, leave)
            end
        end
    end
    state.leave_bufs = {}

    -- Delete user mappings
    for lhs, element in pairs(state.submode_to_user_mappings[state.current_mode] or {}) do
        if element.opts and element.opts.buffer then
            vim.keymap.del(opts.mode, lhs, { buffer = element.opts.buffer })
        else
            vim.keymap.del(opts.mode, lhs)
        end
    end

    -- Delete default mappings
    for lhs, element in pairs(state.submode_to_default_mappings[state.current_mode] or {}) do
        if state.submode_to_user_mappings[name][lhs] then
            goto continue
        end
        if element.opts and element.opts.buffer then
            vim.keymap.del(opts.mode, lhs, { buffer = element.opts.buffer })
        else
            vim.keymap.del(opts.mode, lhs)
        end
        ::continue::
    end

    -- Restore previous keymaps from created snapshot
    state.snapshot:restore(opts.mode)

    state.current_mode = ""

    vim.api.nvim_exec_autocmds("User", {
        pattern = "SubmodeLeavePost",
        modeline = false,
        data = {
            name = name,
        },
    })
    opts.hook.on_leave()
end

return M
