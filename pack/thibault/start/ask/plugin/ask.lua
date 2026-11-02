if vim.g.loaded_ask then return end
vim.g.loaded_ask = true

vim.keymap.set('x', '<leader>?', function() require('ask').ask() end, { desc = '[?] Ask an agent about the selection' })
vim.keymap.set('n', '<leader>A', function() require('ask').pick() end, { desc = '[A]sk threads' })
