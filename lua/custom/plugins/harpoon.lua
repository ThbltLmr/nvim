-- harpoon (telescope is already added in section 4, plenary as a dep too)
vim.pack.add {
  { src = 'https://github.com/ThePrimeagen/harpoon', version = 'harpoon2' },
}

local harpoon = require 'harpoon'
harpoon:setup {}

vim.keymap.set('n', '<leader>h', function() harpoon.ui:toggle_quick_menu(harpoon:list()) end, { desc = '[H]arpoon menu' })
vim.keymap.set('n', '<leader>a', function() harpoon:list():add() end, { desc = 'Harpoon [A]dd file' })

vim.keymap.set('n', '<leader>1', function() harpoon:list():select(1) end, { desc = 'Harpoon file 1' })
vim.keymap.set('n', '<leader>2', function() harpoon:list():select(2) end, { desc = 'Harpoon file 2' })
vim.keymap.set('n', '<leader>3', function() harpoon:list():select(3) end, { desc = 'Harpoon file 3' })
vim.keymap.set('n', '<leader>4', function() harpoon:list():select(4) end, { desc = 'Harpoon file 4' })

-- Toggle previous & next buffers stored within Harpoon list
vim.keymap.set('n', '<C-S-P>', function() harpoon:list():prev() end, { desc = 'Harpoon previous' })
vim.keymap.set('n', '<C-S-N>', function() harpoon:list():next() end, { desc = 'Harpoon next' })
