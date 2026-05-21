-- Register the build hook BEFORE vim.pack.add so it fires for the
-- install event that vim.pack emits synchronously.
vim.api.nvim_create_autocmd('PackChanged', {
  callback = function(ev)
    if ev.data.spec.name ~= 'markdown-preview.nvim' then return end
    if ev.data.kind ~= 'install' and ev.data.kind ~= 'update' then return end
    if not ev.data.active then vim.cmd.packadd 'markdown-preview.nvim' end
    pcall(vim.fn['mkdp#util#install'])
  end,
})

vim.pack.add { 'https://github.com/iamcco/markdown-preview.nvim' }

-- Heal an unbuilt install (e.g. previous run where the hook didn't fire):
-- if the server binary is missing, build it now.
local plugin_root = vim.fn.stdpath 'data' .. '/site/pack/core/opt/markdown-preview.nvim'
if vim.fn.isdirectory(plugin_root .. '/app/bin') == 0 then
  vim.cmd.packadd 'markdown-preview.nvim'
  pcall(vim.fn['mkdp#util#install'])
end

vim.g.mkdp_browser = ''

vim.keymap.set('n', '<leader>mp', '<cmd>MarkdownPreview<cr>', { desc = 'Markdown Preview' })
vim.keymap.set('n', '<leader>MP', '<cmd>MarkdownPreview<cr>', { desc = 'Markdown Preview' })
