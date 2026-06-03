-- octo.nvim — GitHub issues / PRs / reviews inside Neovim (needs the `gh` CLI, authenticated).
-- diffview.nvim powers the changed-files panel during a review.
-- Deps (plenary, telescope, nvim-web-devicons) are already installed in init.lua.
vim.pack.add {
  'https://github.com/sindrets/diffview.nvim',
  'https://github.com/pwntester/octo.nvim',
}

require('diffview').setup {}
require('octo').setup {
  picker = 'telescope', -- reuse your existing Telescope picker
  -- Map SSH host aliases (~/.ssh/config) back to the real host so `gh` finds the account.
  -- octo escapes hyphens internally, so keys are the literal alias names.
  ssh_aliases = {
    ['github-hublo'] = 'github.com',
    ['github-biogroup'] = 'github.com',
  },
}

-- which-key group label for <leader>o
pcall(function() require('which-key').add { { '<leader>o', group = 'Octo / GitHub' } } end)

local map = function(lhs, rhs, desc) vim.keymap.set('n', lhs, rhs, { desc = desc }) end

-- Browse / pick PRs
map('<leader>op', '<cmd>Octo pr list<cr>', 'PR list')
map('<leader>os', '<cmd>Octo pr search<cr>', 'PR search')
map('<leader>oo', '<cmd>Octo pr checkout<cr>', 'PR checkout (local branch)')
map('<leader>od', '<cmd>Octo pr diff<cr>', 'PR diff (changed files)')
map('<leader>ob', '<cmd>Octo pr browser<cr>', 'Open PR in browser')

-- Review lifecycle
map('<leader>or', '<cmd>Octo review start<cr>', 'Review: start')
map('<leader>oe', '<cmd>Octo review resume<cr>', 'Review: resume')
map('<leader>oR', '<cmd>Octo review submit<cr>', 'Review: submit')
map('<leader>ox', '<cmd>Octo review discard<cr>', 'Review: discard')

-- Comments / threads
map('<leader>oc', '<cmd>Octo comment add<cr>', 'Comment: add')
map('<leader>oC', '<cmd>Octo comment delete<cr>', 'Comment: delete')

-- Issues
map('<leader>oi', '<cmd>Octo issue list<cr>', 'Issue list')
