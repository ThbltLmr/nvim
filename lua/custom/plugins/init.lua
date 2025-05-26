-- You can add your own plugins here or in other files in this directory!
--  I promise not to create any merge conflicts in this directory :)
--
-- See the kickstart.nvim README for more information
return {
  {
    'nvzone/typr',
    dependencies = 'nvzone/volt',
    opts = {},
    cmd = { 'Typr', 'TyprStats' },
  },
  {
    'milanglacier/minuet-ai.nvim',
    enabled = false,
    config = function()
      require('minuet').setup {
        enabled = true,
        provider = 'gemini',
        n_completions = 1, -- recommend for local model for resource saving
        -- I recommend beginning with a small context window size and incrementally
        -- expanding it, depending on your local computing power. A context window
        -- of 512, serves as an good starting point to estimate your computing
        -- power. Once you have a reliable estimate of your local computing power,
        -- you should adjust the context window to a larger value.
        context_window = 512,
        provider_options = {
          gemini = {
            enabled = false,
            model = 'gemini-2.0-flash',
            stream = true,
            api_key = 'GEMINI_API_KEY',
            optional = {
              generationConfig = {
                maxOutputTokens = 256,
              },
              safetySettings = {
                {
                  -- HARM_CATEGORY_HATE_SPEECH,
                  -- HARM_CATEGORY_HARASSMENT
                  -- HARM_CATEGORY_SEXUALLY_EXPLICIT
                  category = 'HARM_CATEGORY_DANGEROUS_CONTENT',
                  -- BLOCK_NONE
                  threshold = 'BLOCK_ONLY_HIGH',
                },
              },
            },
          },
          openai_fim_compatible = {
            api_key = 'OLLAMA',
            name = 'Ollama',
            end_point = 'http://localhost:11434/v1/completions',
            model = 'qwen2.5-coder:7b',
            optional = {
              max_tokens = 256,
              top_p = 0.9,
              generationConfig = {
                maxOutputTokens = 512,
              },
            },
          },
        },
      }
    end,
  },
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
  {
    'm4xshen/hardtime.nvim',
    lazy = false,
    dependencies = { 'MunifTanjim/nui.nvim' },
    opts = {},
  },
  {
    'github/copilot.vim',
    lazy = false,
  },
}
