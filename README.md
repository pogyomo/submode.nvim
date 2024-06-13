# :wrench: submode.nvim

This plugin privide apis to create a submode and manipulate it.

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

The submode is on normal mode, and you can enter this submode by pressing `<C-w>` when in normal mode. Once you enter this submode, you can use `hjkl` to move around windows, and finally you can exit from this submode by pressing `q` or `escape`.

## :inbox_tray: Installation

With [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
return {
    "pogyomo/submode.nvim",
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
}, {
    lhs = "d",
    rhs = vim.lsp.buf.definition,
}, {
    lhs = "D",
    rhs = vim.lsp.buf.declaration,
}, {
    lhs = "H",
    rhs = vim.lsp.buf.hover,
}, {
    lhs = "i",
    rhs = vim.lsp.buf.implementation,
}, {
    lhs = "r",
    rhs = vim.lsp.buf.references,
})
```

* Enable keymaps which is appropriate for reading help when open help.

```lua
local submode = require("submode")

submode.create("DocReader", {
    mode = "n",
}, {
    lhs = "<Enter>",
    rhs = "<C-]>",
}, {
    lhs = "u",
    rhs = "<cmd>po<cr>",
}, {
    lhs = { "r", "U" },
    rhs = "<cmd>ta<cr>",
}, {
    lhs = "q",
    rhs = "<cmd>q<cr>",
})

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

## :desktop_computer: APIS

- `setup(config)`
    - Initialize this plugin.
    - `config?: table` Config of the submode. Have the following fields.
        - `leave_when_mode_changed?: boolean` Whether leave from current submode or not when mode is changed. Default is false.
        - `when_mapping_exist?: string` Behavior when mapping already exist. Accept following strings.
            - `"error"` Throw error. This is default.
            - `"keep"` Keep current mapping.
            - `"override"` Override old mapping.
        - `when_submode_exist?: string` Behavior when submode already exist. Accept following strings.
            - `"error"` Throw error. This is default.
            - `"keep"` Keep current submode.
            - `"override"` Override old submode.

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
    - `...: table` Mappings for this submode. Have the following fields.
        - `lhs: string | string[]` Lhs of keymap. Same as `lhs` of `vim.keymap.set`. Can be multiple.
        - `rhs: string | fun():string?` Rhs of keymap. Same as `rhs` of `vim.keymap.set`.
        - `opts?: table` Options of this keymap. Same as `opts` of `vim.keymap.set`.

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
    - `opts?: table` Options for this deletion. Currently no option is available.

- `enter(name)`
    - Enter the submode. This function only have effect if parent mode of the submode is same as current mode.
    - `name: string` Name of submode to enter.

- `leave()`
    - Leave from current submode. Nothing happen when we are not in submode.

- `mode(): string | nil`
    - Get current submode's name. Returns nil if not in submode, or `show_mode` is `false`.
