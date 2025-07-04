return {
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
}
