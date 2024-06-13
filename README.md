# :wrench: submode.nvim

This plugin privide apis to create a submode and manipulate it. 

These apis can be used on-the-fly: no need to call config like other plugin.

## :clipboard: Requirements

* Neovim >= 0.10.0

## :notebook: Introduction

This plugin allow users to create submode, which has almost same keymaps as the parent mode like normal, insert, etc, but some keymaps is changed and is defined by user.

For example, when we try to move around windows, we need to press `<C-w>h`, `<C-w>j`, `<C-w>k` and `<C-w>l` multiple times.
Therefore, it would be useful to be able to press `<C-w>` and then `hjkl` to move the window.

Fortunately, you can define such submode as follow.

```lua
local submode = require("submode")
submode.create("WinMove", {
    mode = "n",
    enter = "<C-w>",
    leave = { "q", "<ESC>" },
})
submode.default("WinMove", "h", "<C-w>h")
submode.default("WinMove", "j", "<C-w>j")
submode.default("WinMove", "k", "<C-w>k")
submode.default("WinMove", "l", "<C-w>l")
```

This submode has default mappings `hjkl` for moving around windows, and you can enter this submode by pressing `<C-w>` when in normal mode. Once you enter this submode, you can use `hjkl`. You can leave from this submode by pressing `q` or `escape`, and after that `hjkl` cannot be used to move windows anymore.

You can write the submode only use `submode.create` if you want:

```lua
local submode = require("submode")
submode.create("WinMove", {
    mode = "n",
    enter = "<C-w>",
    leave = { "q", "<ESC>" },
}, {
    lhs = "h",
    rhs = "<C-w>h",
}, {
    lhs = "j",
    rhs = "<C-w>j",
}, {
    lhs = "k",
    rhs = "<C-w>k",
}, {
    lhs = "l",
    rhs = "<C-w>l",
})
```

Next, sometimes you may want to add a mappings to exist submode to extend the behavior of the submode. Is it possible in this plugin? The answer is yes. 

For example, you have a submode defined as follow.

```lua
local submode = require("submode")
submode.create("test", {
    mode = "n",
    enter = "]",
    leave = { "q", "<ESC>" },
})
submode.default("test", "1", function() vim.notify("1") end)
```

Then, if you want to add `2` to notify `2`, you can achieve it with the following code.

```lua
submode.set("test", "2", function() vim.notify("2") end)
```

Using the `submode.set`, you can add arbitrary mappings to a submode. This interface is compatible with `vim.keymap.set`, so you can easily define mappings the way you are used to.

Just as neovim provides `vim.keymap.del`, this plugin provides its compatible interface: `submode.del`. You can use it like as `vim.keymap.set`.

```lua
submode.del("test", "2")
```

One additional notable point is that mappings created by `submode.create`, or defined by `submode.default` doesn't change as if `submode.set` and `submode.del` is called in the order. 

For example, if we call `submode.set("test", "1", "")`, this disable the behavior of `1` in `test`, but if we call `submode.del("test", "1")` after that, pressing `1` will notify `1`.

## :inbox_tray: Installation

With [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
return {
    "pogyomo/submode.nvim",
    lazy = true,
    -- (recommended) specify version to prevent unexpected change.
    -- version = "5.2.0",
}
```

## :bulb: Examples

* Submode to switch to lsp-related keymaps.

```lua
local submode = require("submode")

submode.create("LspOperator", {
    mode = "n",
    enter = "<Space>l",
    leave = { "q", "<ESC>" },
})
submode.default("LspOperator", "d", vim.lsp.buf.definition)
submode.default("LspOperator", "D", vim.lsp.buf.declaration)
submode.default("LspOperator", "H", vim.lsp.buf.hover)
submode.default("LspOperator", "i", vim.lsp.buf.implementation)
submode.default("LspOperator", "r", vim.lsp.buf.references)
```

* Enable keymaps which is appropriate for reading help when open help.

```lua
local submode = require("submode")

submode.create("DocReader", {
    mode = "n",
})
submode.default("DocReader", "<Enter>", "<C-]>")
submode.default("DocReader", "u", "<cmd>po<cr>")
submode.default("DocReader", "r", "<cmd>ta<cr>")
submode.default("DocReader", "U", "<cmd>ta<cr>")
submode.default("DocReader", "q", "<cmd>q<cr>")

vim.api.nvim_create_augroup("DocReaderAugroup", {})
vim.api.nvim_create_autocmd("BufEnter", {
    group = "DocReaderAugroup",
    callback = function()
        if vim.opt.ft:get() == "help" and not vim.bo.modifiable then
            submode.enter("DocReader")
        end
    end,
})
vim.api.nvim_create_autocmd({ "BufLeave", "CmdwinEnter" }, {
    group = "DocReaderAugroup",
    callback = function()
        if submode.mode() == "DocReader" then
            submode.leave()
        end
    end,
})
```

## :date: User Events

The following user events will be triggered.

- `SubmodeEnterPre` 
    - Emitted when `submode.enter` called and before process anything.
    - `data` attribute will hold `name` for corresponding submode name.
- `SubmodeEnterPost` 
    - Emitted when `submode.enter` called and after all process done.
    - `data` attribute will hold `name` for corresponding submode name.
- `SubmodeLeavePre` 
    - Emitted when `submode.leave` called and before process anything.
    - `data` attribute will hold `name` for corresponding submode name.
- `SubmodeLeavePost` 
    - Emitted when `submode.leave` called and after all process done.
    - `data` attribute will hold `name` for corresponding submode name.

## :desktop_computer: APIS

- `create(name, info, ...)`
    - Create a new submode.
    - `name: string` Name of this submode.
    - `info: table` Infomation of this submode. Have the following fields.
        - `mode: string` Parent mode of this submode like `"n"`, `"v"`, etc.
        - `show_mode?: boolean` False to suppress `mode()` returns the submode name.
        - `mode_name?: string | fun(): string` Change the value `mode()` returns.
        - `enter?: string | string[]` Keys to enter to this submode.
        - `leave?: string | string[]` Keys to leave from this submode.
        - `enter_cb?: function` Callback to be called when enter to submode.
        - `leave_cb?: function` Callback to be called when leave from submode.
        - `leave_when_mode_changed?: boolean` Whether leave from current submode or not when parent mode is changed i.e. changed normal mode to visual mode. Default is false.
        - `override_behavior?: string` Behavior when the submode already exist. Accept following strings.
            - `"error"` Throw error. This is default.
            - `"keep"` Keep current submode.
            - `"override"` Override old submode.
    - `...: table` Default mappings for this submode. The functional is same as `submode.default`. Have the following fields.
        - `lhs: string` Lhs of mapping.
        - `rhs: string | fun():string?` Rhs of mapping. Can be function.
        - `opts?: table` Options of this mapping. Same as `opts` of `vim.keymap.set`.

- `default(name, lhs, rhs, opts)`
    - Add a default mapping to `name`. The default mapping doesn't change when we calls `submode.set` and `submode.del` for the mapping. Same interface as `vim.keymap.set`.
    - `name: string` Name of target submode.
    - `lhs: string` Lhs of mapping.
    - `rhs: string | fun():string?` Rhs of mapping. Can be function.
    - `opts?: table` Options of this mapping. Same as `opts` of `vim.keymap.set`.

- `set(name, lhs, rhs, opts)`
    - Add a mapping to `name`. Same interface as `vim.keymap.set`.
    - `name: string` Name of target submode.
    - `lhs: string` Lhs of mapping.
    - `rhs: string | fun():string?` Rhs of mapping. Can be function.
    - `opts?: table` Options of this mapping. Same as `opts` of `vim.keymap.set`.

- `del(name, lhs, opts)`
    - Delete a mapping from `name`. Same interface as `vim.keymap.del`.
    - `name: string` Name of target submode.
    - `lhs: string` Lhs of mapping.
    - `opts?: table` Options for this deletion. Same as `opts` of `vim.keymap.del`.

- `enter(name)`
    - Enter the submode. This function only have effect if parent mode of the submode is same as current mode.
    - `name: string` Name of submode to enter.

- `leave()`
    - Leave from current submode. Nothing happen when we are not in submode.

- `mode(): string | nil`
    - Get current submode's name. Returns nil if not in submode, or `show_mode` is `false`.
