-- lua/kupo/core/jetski-prompt.lua
-- Unified prompt box (<leader>rp) supporting slash commands (/ask, /refine, /glowup, /edit).
-- Preserves visual selection before leaving visual mode and opens custom multi-line input box.

local jetski_ui = require("kupo.core.jetski-ui")
local jetski_region = require("kupo.core.jetski-region")

local M = {}
local is_asking = false

local completions = {
	{ word = "/ask ", abbr = "/ask", menu = "answer in a popup (read-only)" },
	{ word = "/refine ", abbr = "/refine", menu = "conservative tidy of structure & formatting" },
	{ word = "/glowup ", abbr = "/glowup", menu = "clean headings + visual markers, easy to scan" },
	{ word = "/edit ", abbr = "/edit", menu = "rewrite per instruction" },
}

--- Parse slash command intent deterministically.
--- @param input string
--- @return string, string
local function parse_intent(input)
	local cmd, args = input:match("^%s*/(%a+)%s*(.*)$")
	if cmd then
		cmd = cmd:lower()
		if cmd == "ask" or cmd == "refine" or cmd == "glowup" or cmd == "edit" then
			return cmd, args
		end
	end
	return "edit", input
end

--- Handle /ask command by opening read-only popup with Jetski response.
--- @param bufnr integer
--- @param sel table
--- @param is_visual boolean
--- @param question string
local function handle_ask(bufnr, sel, is_visual, question)
	if is_asking then
		vim.notify("Jetski ask query is already in progress", vim.log.levels.WARN)
		return
	end
	is_asking = true

	vim.cmd("silent write")

	local filepath = vim.api.nvim_buf_get_name(bufnr)
	local prompt
	if is_visual then
		local text = jetski_ui.selected_text(bufnr, sel)
		prompt = "Question about lines "
			.. sel.start_line
			.. "–"
			.. sel.end_line
			.. " of file "
			.. filepath
			.. ":\n\n```markdown\n"
			.. text
			.. "\n```\n\nQuestion: "
			.. question
	else
		prompt = "Question about file " .. filepath .. ": " .. question
	end

	local spinner = jetski_ui.open_spinner("Asking Jetski…")
	local extra_args = { "--permission-mode", "default", "--allowedTools", "Read,Grep,Glob" }

	jetski_ui.run(prompt, extra_args, function(result)
		jetski_ui.close_spinner(spinner)
		is_asking = false

		if result.code ~= 0 or not result.stdout then
			local err = (result.stderr and result.stderr ~= "") and result.stderr or "No response from Jetski"
			vim.notify("Jetski ask failed: " .. err, vim.log.levels.ERROR)
			return
		end

		local lines = vim.split(result.stdout, "\n", { plain = true })

		local popup_buf = vim.api.nvim_create_buf(false, true)
		vim.bo[popup_buf].filetype = "markdown"
		vim.bo[popup_buf].bufhidden = "wipe"
		vim.api.nvim_buf_set_lines(popup_buf, 0, -1, false, lines)
		vim.bo[popup_buf].modifiable = false

		local width = math.min(90, vim.o.columns - 8)
		local height = math.min(30, math.max(10, #lines + 2))
		local row = math.floor((vim.o.lines - height) / 2)
		local col = math.floor((vim.o.columns - width) / 2)

		local popup_win = vim.api.nvim_open_win(popup_buf, true, {
			relative = "editor",
			row = row,
			col = col,
			width = width,
			height = height,
			border = "rounded",
			style = "minimal",
			title = " Jetski Answer ",
			title_pos = "center",
		})

		vim.wo[popup_win].wrap = true
		vim.wo[popup_win].linebreak = true
		vim.wo[popup_win].conceallevel = 2

		local close_popup = function()
			if vim.api.nvim_win_is_valid(popup_win) then
				vim.api.nvim_win_close(popup_win, true)
			end
		end

		vim.keymap.set("n", "q", close_popup, { buffer = popup_buf, noremap = true, silent = true })
		vim.keymap.set("n", "<Esc>", close_popup, { buffer = popup_buf, noremap = true, silent = true })

		vim.cmd("redraw")
	end)
end

-- Keymap <leader>rp in normal and visual mode
vim.keymap.set({ "n", "x" }, "<leader>rp", function()
	local bufnr = vim.api.nvim_get_current_buf()
	local sel = jetski_ui.visual_selection()
	local is_visual = (sel ~= nil)
	if not sel then
		sel = jetski_region.target_selection(bufnr)
	end
	jetski_ui.leave_visual_mode()

	local scope = is_visual and ("lines " .. sel.start_line .. "–" .. sel.end_line) or "whole note"
	local title = "Jetski · " .. scope .. " · type / for commands"

	jetski_ui.input({ title = title, completions = completions }, function(input)
		if not input or input:match("^%s*$") then
			return
		end

		local cmd, args = parse_intent(input)
		local snippet = jetski_ui.selected_text(bufnr, sel)

		if cmd == "ask" then
			handle_ask(bufnr, sel, is_visual, args)
		elseif cmd == "refine" then
			local prompt = jetski_region.refine_prompt(snippet, args)
			jetski_region.edit_selection(bufnr, sel, prompt, "Refining…")
		elseif cmd == "glowup" then
			local prompt = jetski_region.glowup_prompt(snippet, args)
			jetski_region.edit_selection(bufnr, sel, prompt, "Glowing up…")
		elseif cmd == "edit" then
			local prompt = jetski_region.edit_prompt(args, snippet)
			jetski_region.edit_selection(bufnr, sel, prompt, "Editing…")
		end
	end)
end, { desc = "Jetski prompt box" })

return M
