-- leetcode.nvim — solve LeetCode problems inside Neovim.
-- Deps already installed elsewhere: telescope + plenary (init.lua §4),
-- nvim-web-devicons (init.lua), html treesitter parser (init.lua parsers list),
-- and nui.nvim (added by custom/plugins/hardtime.lua). nui is re-listed here so
-- this file stands on its own — vim.pack dedupes identical sources.
vim.pack.add {
  'https://github.com/MunifTanjim/nui.nvim',
  'https://github.com/kawre/leetcode.nvim',
}

require('leetcode').setup {
  arg = 'leetcode.nvim', -- `nvim leetcode.nvim` opens it standalone
  lang = 'python3', -- default language for newly opened problems; switch per-problem with :Leet lang
  picker = { provider = 'telescope' }, -- reuse the existing Telescope picker
  plugins = {
    -- We load leetcode.nvim alongside the normal config (not as a standalone
    -- nvim session), so allow it to run with other buffers open. Exit with :Leet exit.
    non_standalone = true,
  },
}

-- which-key group label for <leader>l
pcall(function() require('which-key').add { { '<leader>l', group = '[L]eetCode' } } end)

local map = function(lhs, rhs, desc) vim.keymap.set('n', lhs, rhs, { desc = desc }) end

-- Open / browse
map('<leader>ll', '<cmd>Leet<cr>', 'LeetCode: dashboard')
map('<leader>lp', '<cmd>Leet list<cr>', 'LeetCode: problem list')
map('<leader>ld', '<cmd>Leet daily<cr>', 'LeetCode: daily challenge')
map('<leader>lz', '<cmd>Leet random<cr>', 'LeetCode: random problem')

-- Solve loop
map('<leader>lr', '<cmd>Leet run<cr>', 'LeetCode: run / test')
map('<leader>ls', '<cmd>Leet submit<cr>', 'LeetCode: submit')
map('<leader>lc', '<cmd>Leet console<cr>', 'LeetCode: console')
map('<leader>li', '<cmd>Leet info<cr>', 'LeetCode: info')

-- Buffer / view
map('<leader>lL', '<cmd>Leet lang<cr>', 'LeetCode: change language')
map('<leader>lt', '<cmd>Leet desc toggle<cr>', 'LeetCode: toggle description')
map('<leader>lo', '<cmd>Leet open<cr>', 'LeetCode: open in browser')
map('<leader>lx', '<cmd>Leet reset<cr>', 'LeetCode: reset to template')
map('<leader>lq', '<cmd>Leet exit<cr>', 'LeetCode: exit')
