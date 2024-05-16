# submode.nvim

This plugin privide apis to create a submode and manipulate it.

## Examples

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
