return {
  -- <Tab> in the question box cycles through these in order. The first is the default.
  -- `adapter` names a file in lua/ask/adapters/. An optional `thinking` level is passed to pi.
  profiles = {
    { name = 'luna', adapter = 'pi', model = 'openai-codex/gpt-6-luna', thinking = 'xhigh' },
    { name = 'opus', adapter = 'claude', model = 'opus' },
    { name = 'deepseek-flash', adapter = 'pi', model = 'opencode-go/deepseek-v4.1-flash' },
  },

  system_prompt = [[
You are answering a developer's question about code they are reading in Neovim.
The code they selected is in a <selection> tag. If it has unsaved="true", the file on disk may differ from the selection, so trust the selection.

- Answer the question directly first, then explain the mechanism and why the code works this way.
- Verify your claims by reading the code instead of guessing, and say so when you are unsure.
- Cite the code you rely on as `path:line` in inline code, with paths relative to the working directory.
- Do not change any files unless the question explicitly asks you to.
- Your answer is shown as markdown in a narrow editor split, so avoid wide tables.]],

  -- Linux limits a single command-line argument to 128 KiB, and the prompt is passed as one.
  max_selection_bytes = 100 * 1024,
}
