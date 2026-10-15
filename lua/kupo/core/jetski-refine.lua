-- lua/kupo/core/jetski-refine.lua
-- Locked whole-note refine (<leader>rf).
-- Saves buffer, locks buffer during execution so user cannot introduce conflicting edits,
-- runs /refine-note slash command headlessly against disk file, and reloads changes with :checktime.

local jetski_ui = require("kupo.core.jetski-ui")

local M = {}
local is_running = false

--- Refine current active note buffer on disk using /refine-note slash command.
function M.refine_current_note()
	if is_running then
		vim.notify("Jetski whole-note refine is already running", vim.log.levels.WARN)
		return
	end
	is_running = true

	local bufnr = vim.api.nvim_get_current_buf()
	local filepath = vim.api.nvim_buf_get_name(bufnr)

	if filepath == "" then
		vim.notify("Cannot refine unnamed buffer", vim.log.levels.ERROR)
		is_running = false
		return
	end

	-- Save unsaved changes to disk before running Jetski against the file
	vim.cmd("silent write")

	-- Lock buffer to prevent concurrent edits during file-level modification
	local saved = jetski_ui.lock_buffer(bufnr)
	local spinner = jetski_ui.open_spinner("Refining note…")

	local extra_args = { "--permission-mode", "acceptEdits" }

	jetski_ui.run("/refine-note " .. filepath, extra_args, function(result)
		jetski_ui.close_spinner(spinner)
		jetski_ui.unlock_buffer(bufnr, saved)
		is_running = false

		if result.code ~= 0 then
			local err = (result.stderr and result.stderr ~= "") and result.stderr or "Command failed"
			vim.notify("Refine error: " .. err, vim.log.levels.ERROR)
			return
		end

		-- CRITICAL GOTCHA: Reload modified disk file and redraw
		vim.cmd("checktime")
		vim.cmd("redraw")
		vim.notify("Note refined ✔", vim.log.levels.INFO)
	end)
end

-- Keymap <leader>rf in normal mode
vim.keymap.set("n", "<leader>rf", function()
	M.refine_current_note()
end, { desc = "Jetski refine whole note (locked)" })

return M
