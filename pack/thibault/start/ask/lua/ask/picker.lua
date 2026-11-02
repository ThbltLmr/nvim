local markers = { running = '*', error = '!', stopped = '-' }

--- A Telescope picker over the threads from this nvim session.
---@param threads table[]
---@param on_select fun(thread: table)
return function(threads, on_select)
  local actions = require 'telescope.actions'
  local action_state = require 'telescope.actions.state'

  require('telescope.pickers')
    .new({}, {
      prompt_title = 'Ask threads',
      finder = require('telescope.finders').new_table {
        results = threads,
        entry_maker = function(thread)
          local display = ('%s %s  [%s]'):format(markers[thread.status] or ' ', thread.title, thread.profile.name)
          return { value = thread, display = display, ordinal = thread.title }
        end,
      },
      sorter = require('telescope.config').values.generic_sorter {},
      previewer = require('telescope.previewers').new_buffer_previewer {
        title = 'Answer',
        define_preview = function(self, entry)
          vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, vim.api.nvim_buf_get_lines(entry.value.buf, 0, -1, false))
          vim.bo[self.state.bufnr].filetype = 'markdown'
        end,
      },
      attach_mappings = function(prompt_bufnr)
        actions.select_default:replace(function()
          local entry = action_state.get_selected_entry()
          actions.close(prompt_bufnr)
          if entry then on_select(entry.value) end
        end)
        return true
      end,
    })
    :find()
end
