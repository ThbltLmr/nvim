return {
  {
    'olimorris/codecompanion.nvim',
    config = true,
    opts = {
      strategies = {
        chat = {
          adapter = 'gemini',
        },
        inline = {
          adapter = 'gemini',
        },
      },
      adapters = {
        gemini = function()
          return require('codecompanion.adapters').extend('gemini', {
            schema = {
              model = {
                default = 'gemini-2.5-flash-preview-05-20',
              },
            },
          })
        end,
      },
      prompt_library = {
        ['YOLO commit'] = {
          strategy = 'workflow',
          description = 'Commits all changes with generated message',
          opts = {
            auto_submit = true,
          },
          prompts = {
            {
              {
                role = 'user',
                content = function()
                  vim.g.codecompanion_auto_tool_mode = true
                  vim.fn.system 'git add .'
                  return string.format(
                    [[@cmd_runner You are an expert at following the Conventional Commit specification. Given the git diff listed below, please generate a commit message for me:

```diff
%s
```
]],
                    vim.fn.system 'git diff --no-ext-diff --staged'
                  )
                end,
                opts = {
                  contains_code = true,
                  auto_submit = true,
                },
              },
            },
            {
              {
                role = 'user',
                content = function()
                  return string.format [[@cmd_runner commit with the generated message]]
                end,
                opts = {
                  contains_code = true,
                  auto_submit = true,
                },
              },
            },
          },
        },
      },
      dependencies = {
        'nvim-lua/plenary.nvim',
        'nvim-treesitter/nvim-treesitter',
      },
    },
  },
}
