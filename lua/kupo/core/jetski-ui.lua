-- lua/kupo/core/jetski-ui.lua
-- Shared helpers for Jetski Neovim integration.
-- Provides vault root detection, buffer lock/unlock, braille spinner with forced redraws,
-- visual selection detection, custom multi-line floating input prompt with slash command completions,
-- and headless Jetski command execution.

local M = {}

-- Constant vault root path (defaults to user's Obsidian vault)
M.vault_root = (vim.fn.isdirectory("/Users/lkupo/Documents/G-Obsidian") == 1) and "/Users/lkupo/Documents/G-Obsidian"
	or (vim.fn.isdirectory("/Users/jkupo/Documents/Resources/Kupo-brain") == 1) and "/Users/jkupo/Documents/Resources/Kupo-brain"
	or vim.fn.expand("~/Documents/G-Obsidian")

--- Lock a buffer by making it read-only and unmodifiable.
--- Returns saved state to pass to unlock_buffer.
--- @param bufnr integer|nil
--- @return table
function M.lock_buffer(bufnr)
	bufnr = bufnr or vim.api.nvim_get_current_buf()
	local saved = {
		modifiable = vim.bo[bufnr].modifiable,
		readonly = vim.bo[bufnr].readonly,
	}
	vim.bo[bufnr].modifiable = false
	vim.bo[bufnr].readonly = true
	return saved
end

--- Restore buffer modifiable and readonly flags.
--- @param bufnr integer|nil
--- @param saved table|nil
function M.unlock_buffer(bufnr, saved)
	bufnr = bufnr or vim.api.nvim_get_current_buf()
	if not saved then
		vim.bo[bufnr].modifiable = true
		vim.bo[bufnr].readonly = false
		return
	end
	vim.bo[bufnr].modifiable = saved.modifiable
	vim.bo[bufnr].readonly = saved.readonly
end

local braille_frames = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }

--- Open a floating braille spinner in top-right corner with high-contrast background.
--- @param label string
--- @return table
function M.open_spinner(label)
	label = label or "Processing..."
	local text = braille_frames[1] .. " " .. label
	local width = #text + 2
	local height = 1

	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, { text })

	-- Define high-contrast highlight group (dark fg on amber bg)
	vim.api.nvim_set_hl(0, "JetskiFloat", { fg = "#000000", bg = "#ffae00", bold = true })

	local win = vim.api.nvim_open_win(buf, false, {
		relative = "editor",
		anchor = "NE",
		row = 1,
		col = vim.o.columns - 2,
		width = width,
		height = height,
		focusable = false,
		style = "minimal",
		border = "rounded",
	})
	vim.wo[win].winhl = "Normal:JetskiFloat,FloatBorder:JetskiFloat"

	local idx = 1
	local timer = vim.uv.new_timer()

	-- Timer tick runs every ~90ms
	timer:start(
		0,
		90,
		vim.schedule_wrap(function()
			if vim.api.nvim_buf_is_valid(buf) then
				idx = (idx % #braille_frames) + 1
				local frame = braille_frames[idx]
				vim.api.nvim_buf_set_lines(buf, 0, -1, false, { frame .. " " .. label })
				-- CRITICAL GOTCHA: Idle Neovim does not repaint automatically during background updates.
				-- Every spinner tick MUST call vim.cmd("redraw") to force rendering.
				vim.cmd("redraw")
			end
		end)
	)

	return { timer = timer, win = win, buf = buf }
end

--- Stop and close a spinner window and timer.
--- @param spinner table|nil
function M.close_spinner(spinner)
	if not spinner then
		return
	end
	if spinner.timer then
		spinner.timer:stop()
		if not spinner.timer:is_closing() then
			spinner.timer:close()
		end
	end
	if spinner.win and vim.api.nvim_win_is_valid(spinner.win) then
		vim.api.nvim_win_close(spinner.win, true)
	end
	if spinner.buf and vim.api.nvim_buf_is_valid(spinner.buf) then
		vim.api.nvim_buf_delete(spinner.buf, { force = true })
	end
end

--- Return current visual selection line range { start_line, end_line } (1-indexed inclusive).
--- Uses getpos("v") and getpos(".") instead of '< and '> (which are stale until visual mode exits).
--- Returns nil if not in visual mode.
--- @return table|nil
function M.visual_selection()
	local mode = vim.fn.mode()
	if mode ~= "v" and mode ~= "V" and mode ~= "\22" then
		return nil
	end
	local pos_v = vim.fn.getpos("v")
	local pos_dot = vim.fn.getpos(".")
	local start_line = pos_v[2]
	local end_line = pos_dot[2]
	if start_line > end_line then
		start_line, end_line = end_line, start_line
	end
	return { start_line = start_line, end_line = end_line }
end

--- Get joined line text for a given selection or full buffer.
--- @param bufnr integer|nil
--- @param selection table|nil { start_line, end_line }
--- @return string
function M.selected_text(bufnr, selection)
	bufnr = bufnr or vim.api.nvim_get_current_buf()
	if not selection then
		local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
		return table.concat(lines, "\n")
	end
	local lines = vim.api.nvim_buf_get_lines(bufnr, selection.start_line - 1, selection.end_line, false)
	return table.concat(lines, "\n")
end

--- Leave visual mode cleanly via feedkeys Esc.
function M.leave_visual_mode()
	local esc = vim.api.nvim_replace_termcodes("<Esc>", true, false, true)
	vim.api.nvim_feedkeys(esc, "nx", false)
end

--- Custom multi-line floating prompt box replacing vim.ui.input.
--- @param opts table { title: string, completions: table|nil }
--- @param on_submit function(input: string|nil)
function M.input(opts, on_submit)
	opts = opts or {}
	local title = opts.title or "Prompt"

	local buf = vim.api.nvim_create_buf(false, true)
	vim.bo[buf].bufhidden = "wipe"

	local width = math.min(90, vim.o.columns - 8)
	local height = 6
	local row = math.floor((vim.o.lines - height) / 2)
	local col = math.floor((vim.o.columns - width) / 2)

	local win = vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		row = row,
		col = col,
		width = width,
		height = height,
		border = "rounded",
		style = "minimal",
		title = " " .. title .. "  —  ⏎ send · Esc cancel ",
		title_pos = "center",
	})

	vim.wo[win].wrap = true
	vim.wo[win].linebreak = true

	local done = false
	local original_completeopt = vim.o.completeopt

	local function cleanup()
		pcall(function()
			vim.o.completeopt = original_completeopt
		end)
		vim.schedule(function()
			if vim.api.nvim_win_is_valid(win) then
				vim.api.nvim_win_close(win, true)
			end
		end)
	end

	local function submit()
		if done then
			return
		end
		done = true
		local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
		cleanup()
		on_submit(table.concat(lines, "\n"))
	end

	local function cancel()
		if done then
			return
		end
		done = true
		cleanup()
		on_submit(nil)
	end

	-- Keymaps inside input box
	-- CRITICAL: Inside expr keymap, schedule submit() so nvim_win_close does not run during expr evaluation (which causes E565)
	vim.keymap.set("i", "<CR>", function()
		if vim.fn.pumvisible() == 1 then
			return "<C-y>"
		else
			vim.schedule(submit)
			return ""
		end
	end, { buffer = buf, expr = true, noremap = true })

	vim.keymap.set("n", "<CR>", submit, { buffer = buf, noremap = true })
	vim.keymap.set({ "i", "n" }, "<C-c>", cancel, { buffer = buf, noremap = true })
	vim.keymap.set("n", "<Esc>", cancel, { buffer = buf, noremap = true })
	vim.keymap.set("n", "q", cancel, { buffer = buf, noremap = true })

	-- Slash command completion setup if completions given
	if opts.completions and #opts.completions > 0 then
		vim.o.completeopt = "menu,menuone,noselect"
		pcall(function()
			require("cmp").setup.buffer({ enabled = false })
		end)

		vim.keymap.set("i", "/", function()
			local line = vim.api.nvim_get_current_line()
			local cur_col = vim.fn.col(".")
			local before = line:sub(1, cur_col - 1)
			if #before:gsub("%s+", "") == 0 then
				vim.schedule(function()
					if vim.fn.mode():sub(1, 1) == "i" and vim.api.nvim_get_current_buf() == buf then
						vim.fn.complete(cur_col + 1, opts.completions)
					end
				end)
			end
			return "/"
		end, { buffer = buf, expr = true, noremap = true })

		vim.keymap.set("i", "<C-j>", function()
			return vim.fn.pumvisible() == 1 and "<C-n>" or ""
		end, { buffer = buf, expr = true, noremap = true })

		vim.keymap.set("i", "<C-k>", function()
			return vim.fn.pumvisible() == 1 and "<C-p>" or ""
		end, { buffer = buf, expr = true, noremap = true })
	end

	vim.cmd("startinsert")
end

--- Run a headless Jetski command with API keys unset in process env.
--- @param prompt string
--- @param extra_args table|nil
--- @param on_done function(obj: table)
function M.run(prompt, extra_args, on_done)
	-- CRITICAL GOTCHA: Unset JETSKI_API_KEY and GEMINI_API_KEY so stale keys exported in shell env don't override jetski authentication
	local jetski_bin = (vim.fn.executable("/usr/local/bin/jetski") == 1) and "/usr/local/bin/jetski" or "jetski"
	local cmd = { "env", "-u", "JETSKI_API_KEY", "-u", "GEMINI_API_KEY", jetski_bin, "-p", prompt }

	if extra_args then
		local i = 1
		while i <= #extra_args do
			local arg = extra_args[i]
			if arg == "--permission-mode" then
				local val = extra_args[i + 1]
				if val == "acceptEdits" then
					table.insert(cmd, "--mode")
					table.insert(cmd, "accept-edits")
				end
				i = i + 2
			elseif arg == "--allowedTools" then
				i = i + 2
			else
				table.insert(cmd, arg)
				i = i + 1
			end
		end
	end

	vim.system(cmd, { text = true, cwd = M.vault_root }, function(obj)
		vim.schedule(function()
			on_done(obj)
		end)
	end)
end

return M
