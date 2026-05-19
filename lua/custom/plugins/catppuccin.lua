-- Override upstream's tokyonight colorscheme with catppuccin-frappe.
-- Loaded after section 3 of init.lua, so this colorscheme call wins.
vim.pack.add { { src = 'https://github.com/catppuccin/nvim', name = 'catppuccin' } }
vim.cmd.colorscheme 'catppuccin-frappe'
