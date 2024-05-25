vim.g.mapleader = " "

local keymap = vim.keymap -- for conciseness

keymap.set("i", "jk", "<ESC>", { desc = "Exit insert mode with jk" })

keymap.set("n", "<leader>nh", ":nohl<CR>", { desc = "Clear search highlights" })

-- increment/decrement numbers
keymap.set("n", "<leader>+", "<C-a>", { desc = "Increment number" }) -- increment
keymap.set("n", "<leader>-", "<C-x>", { desc = "Decrement number" }) -- decrement

-- window management
keymap.set("n", "<leader>sv", "<C-w>v", { desc = "Split window vertically" }) -- split window vertically
keymap.set("n", "<leader>sh", "<C-w>s", { desc = "Split window horizontally" }) -- split window horizontally
keymap.set("n", "<leader>se", "<C-w>=", { desc = "Make splits equal size" }) -- make split windows equal width & height
keymap.set("n", "<leader>sx", "<cmd>close<CR>", { desc = "Close current split" }) -- close current split window

keymap.set("n", "<leader>to", "<cmd>tabnew<CR>", { desc = "Open new tab" }) -- open new tab
keymap.set("n", "<leader>tx", "<cmd>tabclose<CR>", { desc = "Close current tab" }) -- close current tab
keymap.set("n", "<leader>tn", "<cmd>tabn<CR>", { desc = "Go to next tab" }) --  go to next tab
keymap.set("n", "<leader>tp", "<cmd>tabp<CR>", { desc = "Go to previous tab" }) --  go to previous tab
keymap.set("n", "<leader>tf", "<cmd>tabnew %<CR>", { desc = "Open current buffer in new tab" }) --  move current buffer to new tab

-- Resize panes in Neovim using Ctrl+Shift+Arrow keys
keymap.set("n", "<C-S-Left>", "<C-w><", { desc = "Decrease window width" })
keymap.set("n", "<C-S-Right>", "<C-w>>", { desc = "Increase window width" })
keymap.set("n", "<C-S-Up>", "<C-w>-", { desc = "Decrease window height" })
keymap.set("n", "<C-S-Down>", "<C-w>+", { desc = "Increase window height" })

-- Switch tabs using Command + Alt + "h" and "l"
keymap.set("n", "<D-A-h>", ":tabprevious<CR>", { desc = "Go to the previous tab" })
keymap.set("n", "<D-A-l>", ":tabnext<CR>", { desc = "Go to the next tab" })

-- Switch tabs using Command + Alt + "h" and "l"
keymap.set("n", "<D-A-Left>", ":tabprevious<CR>", { desc = "Go to the previous tab" })
keymap.set("n", "<D-A-Right>", ":tabnext<CR>", { desc = "Go to the next tab" })

keymap.set(
	"n",
	"<leader>zf",
	":set foldmethod=indent<CR>",
	{ noremap = true, silent = true, desc = "set foldmethod=indent" }
)
keymap.set(
	"n",
	"<leader>zm",
	":set foldmethod=manual<CR>",
	{ noremap = true, silent = true, desc = "set foldmethod=manual" }
)

-- moving lines - primeagen
keymap.set("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move highlighted lines up" })
keymap.set("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move highlighted lines down" })

keymap.set("n", "<C-d>", "<C-d>zz", { desc = "Keep cursor in the middle while scrolling down" })
keymap.set("n", "<C-u>", "<C-u>zz", { desc = "Keep cursor in the middle while scrolling up" })

keymap.set("n", "n", "nzzzv", { desc = "Allow search terms to stay in the middle" })
keymap.set("n", "N", "Nzzzv", { desc = "Allow search terms to stay in the middle" })

keymap.set("x", "<leader>p", [["_dP]], { desc = "Paste without losing current buffer" })

keymap.set(
	"n",
	"<leader>rw",
	[[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]],
	{ desc = "Replace every occurence of the word I am on" }
)

-- Yank to system clipboard
keymap.set({ "n", "v" }, "<leader>y", [["+y]], { desc = "Yank to system-clipboard" })
keymap.set("n", "<leader>Y", [["+Y]], { desc = "Yank to system-clipboard" })
