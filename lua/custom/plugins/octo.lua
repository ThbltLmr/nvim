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
map('<leader>oT', '<cmd>Octo review thread<cr>', 'Review: open thread under cursor')

-- Comments / threads
map('<leader>oc', '<cmd>Octo comment add<cr>', 'Comment: add')
map('<leader>oC', '<cmd>Octo comment delete<cr>', 'Comment: delete')

-- Issues
map('<leader>oi', '<cmd>Octo issue list<cr>', 'Issue list')

-- ─── Project-specific keymaps ──────────────────────────────────────────────
-- Open PRs authored by my team. GitHub search OR's multiple `author:` qualifiers,
-- so this returns PRs opened by ANY of them. Built as a static search (results
-- shown immediately, no need to type in the prompt) and scoped to the current repo.
local team = {
  'constantgayethublo',
  'ThbltLmrHublo', -- me
  'florent-guille-hublo',
  'louis-grs',
  'vincianelhuissier-ext-lab',
  'alice-rey-h',
  'gatientirel-hublo',
}

local function team_open_prs()
  local query = 'is:pr is:open'
  local ok, repo = pcall(require('octo.utils').get_remote_name) -- "owner/name" of current repo
  if ok and repo and repo ~= '' then query = query .. ' repo:' .. repo end
  for _, user in ipairs(team) do
    query = query .. ' author:' .. user
  end
  require('octo.picker').search { prompt = query, static = true }
end

map('<leader>ot', team_open_prs, 'PRs: open, by my team')
