pcall(function()
	require("vim._core.ui2").enable()
end)

-- plugins
vim.pack.add({
	"https://github.com/mason-org/mason.nvim",
	"https://github.com/neovim/nvim-lspconfig",
	"https://github.com/saghen/blink.lib",
	"https://github.com/saghen/blink.cmp",
	"https://github.com/stevearc/conform.nvim",
	"https://github.com/nvim-mini/mini.nvim",
	"https://github.com/folke/snacks.nvim",
	"https://github.com/ellisonleao/gruvbox.nvim",
	"https://github.com/projekt0n/github-nvim-theme",
})

vim.g.mapleader = " "

-- options
vim.o.wrap = false
vim.o.number = false
vim.o.relativenumber = false
vim.o.signcolumn = "no"
vim.o.cursorline = true
vim.o.expandtab = true
vim.o.tabstop = 4
vim.o.shiftwidth = 4
vim.o.smartindent = true
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.hlsearch = true
vim.o.incsearch = true
vim.o.splitbelow = true
vim.o.splitright = true
vim.o.swapfile = false
vim.o.backup = false
vim.o.undofile = true
vim.o.laststatus = 3
vim.o.winborder = "double"
--

-- basic keymaps
vim.keymap.set("i", "jk", "<Esc>", { desc = "Escape" })
vim.keymap.set("n", "<leader>p", ":pu +<CR>", { desc = "Paste from clipboard to new line below" })
vim.keymap.set("n", "<leader>P", ":pu! +<CR>", { desc = "Paste from clipboard to new line above" })
vim.keymap.set("v", "<leader>p", '"_dP', { desc = "Paste from clipboard without overwriting register" })
vim.keymap.set("v", "<leader>y", '"+y', { silent = true, desc = "Yank selection to clipboard" })
vim.keymap.set("n", "<leader>yy", '"+yy', { silent = true, desc = "Yank line to clipboard" })
vim.keymap.set("n", "<leader>h", "<CMD>nohlsearch<CR>", { silent = true, desc = "Clear search" })
vim.keymap.set("n", "<leader>tl", function()
	vim.o.number = not vim.o.number
	vim.o.relativenumber = not vim.o.relativenumber
	vim.o.signcolumn = (vim.o.signcolumn ~= "no") and "no" or "yes"
end, { silent = true, desc = "Toggle line numbers" })
--

-- highlight on yank
vim.api.nvim_create_autocmd("TextYankPost", {
	desc = "Briefly highlight yanked text",
	group = vim.api.nvim_create_augroup("YankHighlight", { clear = true }),
	callback = function()
		vim.hl.on_yank({
			higroup = "IncSearch",
			timeout = 100,
		})
	end,
})
--

-- tmux-aware window navigation
do
	local stay_when_zoomed = true
	local tmux_dir = { h = "L", j = "D", k = "U", l = "R" }

	local function tmux(...)
		local socket = vim.split(vim.env.TMUX, ",", { plain = true })[1]
		local cmd = { "tmux", "-S", socket, ... }
		local res = vim.system(cmd, { text = true }):wait()
		if res.code ~= 0 then
			vim.notify(("tmux: %s"):format(vim.trim(res.stderr or "")), vim.log.levels.WARN)
			return nil
		end
		return vim.trim(res.stdout or "")
	end

	local function navigate(dir)
		local from = vim.api.nvim_get_current_win()
		vim.cmd.wincmd(dir)
		if vim.api.nvim_get_current_win() ~= from then
			return
		end
		if vim.api.nvim_win_get_config(from).relative ~= "" then
			return
		end
		if vim.env.TMUX == nil or vim.env.TMUX == "" then
			return
		end
		if stay_when_zoomed and tmux("display-message", "-p", "#{window_zoomed_flag}") == "1" then
			return
		end
		tmux("select-pane", "-" .. tmux_dir[dir])
	end

	for key in pairs(tmux_dir) do
		vim.keymap.set({ "n", "t" }, "<C-" .. key .. ">", function()
			navigate(key)
		end, { silent = true, desc = "Move to " .. key .. " window or tmux pane" })
	end
end
--

-- colorscheme based on system theme
require("gruvbox").setup({ bold = false })
do
	local themes = {
		light = "github_light_default",
		dark = "gruvbox",
	}

	local path = vim.fs.normalize("~/.local/state/system-theme")
	local ok, lines = pcall(vim.fn.readfile, path, "", 1)
	local theme = ok and lines[1] and vim.trim(lines[1]) or "dark"

	vim.cmd.colorscheme(themes[theme] or themes.dark)
end
--

-- mason setup
require("mason").setup()
--

-- mini.nvim setup
require("mini.bracketed").setup()
require("mini.bufremove").setup()
require("mini.comment").setup()
require("mini.diff").setup()
require("mini.files").setup()
require("mini.icons").setup()
require("mini.move").setup()
require("mini.pairs").setup()

vim.keymap.set("n", "<leader>e", function()
	if MiniFiles.close() == nil then
		MiniFiles.open()
	end
end, { desc = "Open explorer" })

vim.keymap.set("n", "<leader>tg", function()
	MiniDiff.toggle_overlay()
end, { desc = "Toggle diff overlay" })
--

-- blink setup
local cmp = require("blink.cmp")
cmp.build():pwait()
cmp.setup({ signature = { enabled = true } })
--

-- snacks setup
require("snacks").setup({
	picker = {
		layout = {
			preset = "ivy_split",
		},
	},
})

vim.keymap.set("n", "<leader>fb", function()
	Snacks.picker.buffers()
end, { desc = "Find open buffer" })

vim.keymap.set("n", "<leader>ff", function()
	Snacks.picker.files()
end, { desc = "Find file" })

vim.keymap.set("n", "<leader>fs", function()
	Snacks.picker.grep()
end, { desc = "Grep in files" })

vim.keymap.set("n", "<leader>fw", function()
	Snacks.picker.grep_word()
end, { desc = "Grep current word in files" })

vim.keymap.set("n", "<leader>fq", function()
	Snacks.picker.grep_word()
end, { desc = "Show quickfix list" })

vim.keymap.set("n", "<leader>ws", function()
	Snacks.picker.lsp_workspace_symbols()
end, { desc = "Workspace symbols" })

vim.keymap.set("n", "<leader>ds", function()
	Snacks.picker.lsp_symbols()
end, { desc = "Document symbols" })

vim.keymap.set("n", "<leader>wd", function()
	Snacks.picker.diagnostics()
end, { desc = "Workspace diagnostics" })

vim.keymap.set("n", "<leader>dd", function()
	Snacks.picker.diagnostics_buffer()
end, { desc = "Buffer diagnostics" })

vim.keymap.set("n", "<leader>gl", function()
	Snacks.picker.git_log()
end, { desc = "Git log" })
--

-- formatter setup
local util = require("conform.util")
require("conform").setup({
	default_format_opts = {
		timeout_ms = 5000,
	},
    formatters = {
		pint = {
			cwd = util.root_file({ "pint.json" }),
			require_cwd = true,
		},
		php_cs_fixer = {
			env = { PHP_CS_FIXER_IGNORE_ENV = "true" },
			cwd = util.root_file({ ".php-cs-fixer.php" }),
			require_cwd = true,
		},
	},
	formatters_by_ft = {
		lua = { "stylua" },
		php = { "pint" },
	},
})
vim.keymap.set("n", "<leader>F", function()
	require("conform").format()
end, { silent = true, desc = "Format buffer" })
--

-- lsp setup
vim.diagnostic.config({ virtual_text = false, underline = true, signs = false })
vim.keymap.set("n", "<leader>td", function()
	local status = vim.diagnostic.config().virtual_text
	vim.diagnostic.config({ virtual_text = not status })
end, { silent = true, desc = "Toggle diagnostic virtual text" })

vim.lsp.config("lua_ls", {
	on_init = function(client)
		if client.workspace_folders then
			local path = client.workspace_folders[1].name
			if
				path ~= vim.fn.stdpath("config")
				and (vim.uv.fs_stat(path .. "/.luarc.json") or vim.uv.fs_stat(path .. "/.luarc.jsonc"))
			then
				return
			end
		end

		client.config.settings.Lua = vim.tbl_deep_extend("force", client.config.settings.Lua, {
			workspace = {
				checkThirdParty = false,
				library = {
					vim.env.VIMRUNTIME,
					vim.api.nvim_get_runtime_file("lua/lspconfig", false)[1],
				},
			},
		})
	end,
})

vim.lsp.enable({
	"lua_ls",
	"intelephense",
})
--
