-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
local map = vim.keymap.set

map("n", "<C-w>m", "<cmd>split<cr>", { desc = "Horizontal Split" })
map("n", "<C-w>l", "<cmd>vsplit<cr>", { desc = "Vertical Split" })

map("n", "<C-t>", "<cmd>enew<cr>")
map("n", "<C-h>", "<cmd>bprevious<cr>", { desc = "Prev Buffer" })
map("n", "<C-l>", "<cmd>bnext<cr>", { desc = "Next Buffer" })
map("n", "<C-q>", function()
    Snacks.bufdelete()
end, { desc = "Delete Buffer" })
