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
	"https://github.com/lewis6991/gitsigns.nvim",
	"https://github.com/ellisonleao/gruvbox.nvim",
	"https://github.com/projekt0n/github-nvim-theme",
	"https://github.com/nvim-treesitter/nvim-treesitter",
	"https://github.com/antoinemadec/FixCursorHold.nvim",
	"https://github.com/nvim-neotest/nvim-nio",
	"https://github.com/nvim-neotest/neotest",
	"https://github.com/V13Axel/neotest-pest",
})

vim.g.mapleader = " "

-- options
vim.o.wrap = false
vim.o.number = true
vim.o.relativenumber = true
vim.o.signcolumn = "yes"
vim.o.cursorline = true
vim.o.expandtab = true
vim.o.tabstop = 4
vim.o.softtabstop = 4
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
vim.o.inccommand = "split"
vim.o.updatetime = 250
vim.o.mouse = "a"
--

-- basic keymaps
vim.keymap.set("i", "jk", "<Esc>", { desc = "Escape" })
vim.keymap.set({ "n", "v" }, "<leader>y", '"+y', { silent = true, desc = "Clipboard yank" })
vim.keymap.set({ "n", "v" }, "<leader>Y", '"+Y', { silent = true, desc = "Clipboard line yank" })
vim.keymap.set({ "n", "v" }, "<leader>p", '"+p', { silent = true, desc = "Clipboard paste after cursor" })
vim.keymap.set({ "n", "v" }, "<leader>P", '"+P', { silent = true, desc = "Clipboard paste before cursor" })
vim.keymap.set({ "v" }, "<", "<gv", { silent = true, desc = "Indent" })
vim.keymap.set({ "v" }, ">", ">gv", { silent = true, desc = "Reduce indent" })
vim.keymap.set("n", "<leader>=", ":split<CR>", { noremap = true, silent = true, desc = "Horizontal split" })
vim.keymap.set("n", "<leader>-", ":vsplit<CR>", { noremap = true, silent = true, desc = "Vertical split" })
vim.keymap.set("n", "<leader>h", "<CMD>nohlsearch<CR>", { silent = true, desc = "Clear search" })

vim.keymap.set("n", "<leader>tl", function()
	vim.o.number = not vim.o.number
	vim.o.relativenumber = not vim.o.relativenumber
	-- vim.o.signcolumn = (vim.o.signcolumn ~= "no") and "no" or "yes"
	vim.notify("Line numbers " .. (vim.o.number and "enabled" or "disabled"))
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
require("mini.icons").setup()
require("mini.move").setup()
require("mini.pairs").setup()
--

-- gitsigns setup
require("gitsigns").setup({
	on_attach = function(bufnr)
		local gitsigns = require("gitsigns")

		vim.keymap.set("n", "<leader>gj", function()
			if vim.wo.diff then
				vim.cmd.normal({ "<leader>gj", bang = true })
			else
				gitsigns.nav_hunk("next")
			end
		end, { silent = true, desc = "Goto next hunk" })

		vim.keymap.set("n", "<leader>gk", function()
			if vim.wo.diff then
				vim.cmd.normal({ "<leader>gk", bang = true })
			else
				gitsigns.nav_hunk("prev")
			end
		end, { silent = true, desc = "Goto prev hunk" })

		vim.keymap.set("n", "<leader>gs", gitsigns.stage_hunk, { silent = true, desc = "Stage hunk" })
		vim.keymap.set("n", "<leader>gh", gitsigns.reset_hunk, { silent = true, desc = "Reset hunk" })

		vim.keymap.set("v", "<leader>gs", function()
			gitsigns.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
		end, { silent = true, desc = "Stage hunk" })

		vim.keymap.set("v", "<leader>gh", function()
			gitsigns.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
		end, { silent = true, desc = "Reset hunk" })

		vim.keymap.set("n", "<leader>gl", function()
			gitsigns.blame_line({ full = true })
		end, { silent = true, desc = "Git blame line" })

		vim.keymap.set("n", "<leader>gS", gitsigns.stage_buffer, { silent = true, desc = "Stage buffer" })
		vim.keymap.set("n", "<leader>gr", gitsigns.reset_buffer, { silent = true, desc = "Reset buffer" })
		vim.keymap.set("n", "<leader>gp", gitsigns.preview_hunk, { silent = true, desc = "Preview hunk" })
		vim.keymap.set("n", "<leader>gi", gitsigns.preview_hunk_inline, { silent = true, desc = "Preview hunk inline" })
	end,
})

-- blink setup
local cmp = require("blink.cmp")
cmp.build():pwait()
cmp.setup({ signature = { enabled = true } })
--

-- snacks setup
require("snacks").setup({
	bigfile = { enabled = true },
	explorer = { enabled = true },
	words = { enabled = true },
	input = { enabled = true },
	indent = { indent = { enabled = true }, animate = { enabled = false } },
	picker = {
		enabled = true,
		layout = {
			preset = function()
				return vim.o.columns >= 200 and "default" or "vertical"
			end,
			layout = { width = 0.99, height = 0.8 },
		},
		sources = {
			explorer = {
				layout = { layout = { position = "right", width = 0.3 } },
			},
		},
	},
})

vim.keymap.set("n", "<leader>ff", function()
	Snacks.picker.smart()
end, { desc = "Smart Find Files" })

vim.keymap.set("n", "<leader>e", function()
	Snacks.explorer.open()
end, { desc = "Open explorer" })

vim.keymap.set("n", "<leader>fb", function()
	Snacks.picker.buffers()
end, { desc = "Find open buffer" })

vim.keymap.set("n", "<leader>fs", function()
	Snacks.picker.grep()
end, { desc = "Grep in files" })

vim.keymap.set("n", "<leader>fw", function()
	Snacks.picker.grep_word()
end, { desc = "Grep current word in files" })

vim.keymap.set("n", "<leader>fq", function()
	Snacks.picker.qflist()
end, { desc = "Show quickfix list" })

vim.keymap.set("n", "<leader>lws", function()
	Snacks.picker.lsp_workspace_symbols()
end, { desc = "Workspace symbols" })

vim.keymap.set("n", "<leader>lds", function()
	Snacks.picker.lsp_symbols()
end, { desc = "Document symbols" })

vim.keymap.set("n", "<leader>lwe", function()
	Snacks.picker.diagnostics()
end, { desc = "Workspace diagnostics" })

vim.keymap.set("n", "<leader>lde", function()
	Snacks.picker.diagnostics_buffer()
end, { desc = "Buffer diagnostics" })

vim.keymap.set("n", "<leader>gl", function()
	Snacks.picker.git_log()
end, { desc = "Git log" })

vim.keymap.set("n", "<leader>gb", function()
	Snacks.git.blame_line()
end, { desc = "Git blame line" })
--

-- treesitter setup
require("nvim-treesitter").setup()
require("nvim-treesitter").install({ "blade", "javascript", "lua", "markdown", "php", "twig", "typescript" })
vim.api.nvim_create_autocmd("FileType", {
	group = vim.api.nvim_create_augroup("Treesitter start", { clear = true }),
	pattern = "*",
	callback = function(args)
		pcall(vim.treesitter.start, args.buf)
	end,
})
--

-- neotest setup
require("neotest").setup({
	adapters = {
		require("neotest-pest"),
	},
})
vim.keymap.set("n", "<leader>rn", function()
	require("neotest").run.run()
end, { silent = true, desc = "Run nearest test" })
vim.keymap.set("n", "<leader>rl", function()
	require("neotest").run.run_last()
end, { silent = true, desc = "Run last test run" })
vim.keymap.set("n", "<leader>rf", function()
	require("neotest").run.run(vim.fn.expand("%"))
end, { silent = true, desc = "Run tests in current file" })
vim.keymap.set("n", "<leader>ro", function()
	require("neotest").summary.toggle()
end, { silent = true, desc = "Toggle neotest summary" })
--

-- formatter setup
local util = require("conform.util")
require("conform").setup({
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
		javascript = { "prettier" },
		javascriptreact = { "prettier" },
		json = { "prettier" },
		lua = { "stylua" },
		markdown = { "prettier" },
		php = { "php_cs_fixer", "pint" },
		typescript = { "prettier" },
		typescriptreact = { "prettier" },
		vue = { "prettier" },
	},
})
vim.keymap.set("n", "<leader>lf", function()
	require("conform").format({ timeout_ms = 5000 })
end, { silent = true, desc = "Format buffer" })
--

-- lsp setup
vim.diagnostic.config({ virtual_text = false, underline = true, signs = false })

vim.keymap.set("n", "<leader>td", function()
	local status = vim.diagnostic.config().virtual_text
	vim.diagnostic.config({ virtual_text = not status })
	vim.notify("Diagnostic virtual text " .. (vim.diagnostic.config().virtual_text and "enabled" or "disabled"))
end, { silent = true, desc = "Toggle diagnostic virtual text" })

vim.keymap.set("n", "<leader>tc", function()
	vim.lsp.codelens.enable(not vim.lsp.codelens.is_enabled())
	vim.notify("Codelens " .. (vim.lsp.codelens.is_enabled() and "enabled" or "disabled"))
end, { silent = true, desc = "Toggle LSP codelens" })

vim.keymap.set("n", "<leader>th", function()
	vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
	vim.notify("Inlay hints " .. (vim.lsp.inlay_hint.is_enabled() and "enabled" or "disabled"))
end, { silent = true, desc = "Toggle inlay hints" })

vim.api.nvim_create_autocmd("LspAttach", {
	desc = "Set some keymaps when LSP attaches to buffer",
	callback = function(_)
		vim.keymap.set("n", "K", vim.lsp.buf.hover)
		vim.keymap.set("n", "gD", vim.lsp.buf.declaration)
		vim.keymap.set("n", "gd", require("snacks").picker.lsp_definitions)
		vim.keymap.set("n", "gr", require("snacks").picker.lsp_references)
		vim.keymap.set("n", "gi", require("snacks").picker.lsp_implementations)
		vim.keymap.set("n", "<leader>ll", function()
			vim.lsp.codelens.run()
		end, { desc = "LSP CodeLens Run" })
		vim.keymap.set("n", "<leader>lj", function()
			vim.diagnostic.jump({ count = 1, float = true })
		end)
		vim.keymap.set("n", "<leader>lk", function()
			vim.diagnostic.jump({ count = -1, float = true })
		end)
		vim.keymap.set("n", "<leader>le", vim.diagnostic.open_float)
		vim.keymap.set("n", "<leader>lr", vim.lsp.buf.rename)
		vim.keymap.set({ "n", "v" }, "<leader>la", vim.lsp.buf.code_action)
	end,
})

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

vim.lsp.config("intelephense", {
	commands = {
		-- support peekLocations so we can peek into codelens (like in vscode)
		["editor.action.peekLocations"] = function(cmd, ctx)
			local client = assert(vim.lsp.get_client_by_id(ctx.client_id))
			local locations = cmd.arguments and cmd.arguments[3] or {}
			if #locations == 0 then
				return vim.notify("No locations found", vim.log.levels.INFO)
			end
			if #locations == 1 then
				return vim.lsp.util.show_document(locations[1], client.offset_encoding, { focus = true })
			end
			vim.fn.setqflist({}, " ", {
				title = cmd.title,
				items = vim.lsp.util.locations_to_items(locations, client.offset_encoding),
			})
			require("snacks").picker.qflist()
		end,
	},
	settings = {
		intelephense = {
			codeLens = {
				implementations = { enable = true },
				overrides = { enable = true },
				parent = { enable = true },
				references = { enable = true },
				usages = { enable = true },
			},
		},
	},
})

vim.lsp.config("ts_ls", {
	init_options = {
		plugins = {
			{
				name = "@vue/typescript-plugin",
				location = vim.fn.stdpath("data")
					.. "/mason/packages/vue-language-server/node_modules/@vue/language-server",
				languages = { "vue" },
				configNamespace = "typescript",
			},
		},
		preferences = {
			importModuleSpecifierPreference = "non-relative",
			importModuleSpecifierEnding = "minimal",
		},
	},
	filetypes = { "typescript", "javascript", "javascriptreact", "typescriptreact", "vue" },
	settings = {
		typescript = {
			preferences = {
				importModuleSpecifierPreference = "non-relative",
			},
		},
		javascript = {
			preferences = {
				importModuleSpecifierPreference = "non-relative",
			},
		},
	},
})

vim.lsp.enable({
	"eslint",
	"lua_ls",
	"intelephense",
	"ts_ls",
})
--
