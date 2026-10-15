-- lua/kupo/core/jetski-region.lua
-- Non-locking region engine for Jetski.
-- Anchors selected lines using extmarks so concurrent edits outside the region remain safe.
-- Splices replacement markdown verbatim back into the buffer when complete.
-- Maps <leader>re in normal and visual mode.

local jetski_ui = require("kupo.core.jetski-ui")

local M = {}
local is_running = false

local ns = vim.api.nvim_create_namespace("jetski_region")
vim.api.nvim_set_hl(0, "JetskiRegion", { bg = "#3a301d" })

--- Determine target line selection: visual selection if active, else whole buffer range.
--- @param bufnr integer|nil
--- @return table { start_line: integer, end_line: integer }
function M.target_selection(bufnr)
	bufnr = bufnr or vim.api.nvim_get_current_buf()
	local sel = jetski_ui.visual_selection()
	if sel then
		return sel
	end
	local line_count = vim.api.nvim_buf_line_count(bufnr)
	return { start_line = 1, end_line = math.max(1, line_count) }
end

local CONTRACT = "\n\nOutput ONLY the replacement markdown — the exact text that will replace the region verbatim. No preamble, no explanation, no surrounding code fences."

--- Prompt builder for editing region according to instruction.
function M.edit_prompt(request, snippet)
	return "Rewrite the following markdown text according to this request: " .. request .. "\n\nOriginal text:\n" .. snippet .. CONTRACT
end

--- Prompt builder for conservative refine of structure and formatting.
function M.refine_prompt(snippet, extra)
	local guide = (extra and extra ~= "") and ("\nAdditional guidance: " .. extra) or ""
	return "Refine the following markdown snippet: improve structure, heading hierarchy, list/formatting consistency, spacing, and readability, WITHOUT changing meaning, voice, or content. Preserve frontmatter, [[wikilinks]], ![[embeds]], #tags, and callouts." .. guide .. "\n\nOriginal text:\n" .. snippet .. CONTRACT
end

--- Prompt builder for opinionated visual glowup.
function M.glowup_prompt(snippet, extra)
	local guide = (extra and extra ~= "") and ("\nAdditional guidance: " .. extra) or ""
	return "Give the following markdown snippet an opinionated visual makeover: clean heading hierarchy with no skipped levels, exactly ONE tasteful emoji per major heading, Obsidian callouts (> [!note], > [!tip], > [!important], > [!warning], > [!quote]), --- dividers between major sections, bolded key terms, markdown tables where they genuinely help, walls of text broken into short paragraphs and parallel bullets. Preserve frontmatter, [[wikilinks]], #tags, and ![[embeds]] exactly and invent no new facts." .. guide .. "\n\nOriginal text:\n" .. snippet .. CONTRACT
end

--- Edit a target selection using Jetski read-only output spliced via extmark tracking.
--- @param bufnr integer|nil
--- @param selection table|nil { start_line: integer, end_line: integer }
--- @param prompt string
--- @param label string|nil
function M.edit_selection(bufnr, selection, prompt, label)
	if is_running then
		vim.notify("Jetski is already running", vim.log.levels.WARN)
		return
	end
	is_running = true

	bufnr = bufnr or vim.api.nvim_get_current_buf()
	selection = selection or M.target_selection(bufnr)

	local start_row = selection.start_line - 1
	local end_row = selection.end_line - 1
	local line_count = vim.api.nvim_buf_line_count(bufnr)
	end_row = math.min(end_row, line_count - 1)
	start_row = math.min(start_row, end_row)

	local end_line_text = vim.api.nvim_buf_get_lines(bufnr, end_row, end_row + 1, false)[1] or ""

	-- CRITICAL GOTCHA: Extmarks shift automatically when text is inserted/deleted above.
	-- end_right_gravity ensures text inserted at end of mark extends or stays outside properly.
	local mark_id = vim.api.nvim_buf_set_extmark(bufnr, ns, start_row, 0, {
		end_row = end_row,
		end_col = #end_line_text,
		hl_group = "JetskiRegion",
		hl_eol = true,
		end_right_gravity = true,
	})

	local spinner = jetski_ui.open_spinner(label or "Editing…")

	local extra_args = { "--permission-mode", "default", "--allowedTools", "Read,Grep,Glob" }

	jetski_ui.run(prompt, extra_args, function(result)
		jetski_ui.close_spinner(spinner)
		is_running = false

		if not vim.api.nvim_buf_is_valid(bufnr) then
			return
		end

		if result.code ~= 0 or not result.stdout or result.stdout:match("^%s*$") then
			pcall(vim.api.nvim_buf_del_extmark, bufnr, ns, mark_id)
			local err_msg = (result.stderr and result.stderr ~= "") and result.stderr or "Empty output from Jetski"
			vim.notify("Jetski region edit failed: " .. err_msg, vim.log.levels.ERROR)
			return
		end

		-- Re-read current extmark position (which moved if user typed elsewhere)
		local mark = vim.api.nvim_buf_get_extmark_by_id(bufnr, ns, mark_id, { details = true })
		local current_start_row = mark and mark[1] or start_row
		local current_end_row = (mark and mark[3] and mark[3].end_row) or end_row

		pcall(vim.api.nvim_buf_del_extmark, bufnr, ns, mark_id)

		-- Strip outer code fence defensively
		local text = result.stdout
		text = text:gsub("^\r?\n", ""):gsub("\r?\n$", "")
		text = text:gsub("^```%w*\r?\n", ""):gsub("\r?\n```$", "")

		local new_lines = vim.split(text, "\n", { plain = true })

		-- In-buffer splice on tracked line range
		vim.api.nvim_buf_set_lines(bufnr, current_start_row, current_end_row + 1, false, new_lines)

		-- CRITICAL: Force redraw after splicing results
		vim.cmd("redraw")

		vim.notify("Region edited ✔  (unsaved — review, then :w or undo)", vim.log.levels.INFO)
	end)
end

-- Keymap <leader>re in normal and visual mode
vim.keymap.set({ "n", "x" }, "<leader>re", function()
	local bufnr = vim.api.nvim_get_current_buf()
	local sel = M.target_selection(bufnr)
	jetski_ui.leave_visual_mode()
	local title = "Edit lines " .. sel.start_line .. "–" .. sel.end_line
	jetski_ui.input({ title = title }, function(input)
		if not input or input:match("^%s*$") then
			return
		end
		local text = jetski_ui.selected_text(bufnr, sel)
		local prompt = M.edit_prompt(input, text)
		M.edit_selection(bufnr, sel, prompt, "Editing…")
	end)
end, { desc = "Jetski edit region" })

return M
