vim.pack.add { 'https://github.com/stevearc/oil.nvim' }
require('oil').setup {
  default_file_explorer = false,
  view_options = {
    show_hidden = true,
  },
}

vim.keymap.set('n', '-', '<cmd>Oil<cr>', { desc = 'Open parent directory (Oil)' })
