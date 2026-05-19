vim.pack.add { 'https://github.com/iamcco/markdown-preview.nvim' }

-- Build hook: install the preview script after install/update.
vim.api.nvim_create_autocmd('PackChanged', {
  callback = function(ev)
    if ev.data.spec.name ~= 'markdown-preview.nvim' then return end
    if ev.data.kind ~= 'install' and ev.data.kind ~= 'update' then return end
    if not ev.data.active then vim.cmd.packadd 'markdown-preview.nvim' end
    pcall(vim.fn['mkdp#util#install'])
  end,
})

vim.g.mkdp_browser = ''

vim.keymap.set('n', '<leader>mp', '<cmd>MarkdownPreview<cr>', { desc = 'Markdown Preview' })
vim.keymap.set('n', '<leader>MP', '<cmd>MarkdownPreview<cr>', { desc = 'Markdown Preview' })
