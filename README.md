# submode.nvim

This plugin privide apis to create a submode and manipulate it.

## Examples

* Submode to switch to lsp-related keymaps.

```lua
require("submode").create("LspOperator", {
    mode = "n",
    enter = "<Space>l",
    leave = { "q", "<ESC>" },
}, {
    lhs = "d",
    rhs = function() vim.lsp.buf.definition() end,
}, {
    lhs = "D",
    rhs = function() vim.lsp.buf.declaration() end,
}, {
    lhs = "H",
    rhs = function() vim.lsp.buf.hover() end,
}, {
    lhs = "i",
    rhs = function() vim.lsp.buf.implementation() end,
}, {
    lhs = "r",
    rhs = function() vim.lsp.buf.references() end,
})
```
