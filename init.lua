-- keymaps

vim.g.mapleader = " "

vim.keymap.set("n", "<leader>pv", vim.cmd.Ex)
vim.keymap.set("n", "<leader>t", ":!")

vim.keymap.set('i', 'kj', '<ESC>', {noremap = true})
vim.keymap.set('n', '<c-u>', '<c-u>zz', {noremap = true})
vim.keymap.set('n', '<c-d>', '<c-d>zz', {noremap = true})
vim.keymap.set('i', '<c-n>', '<c-x><c-o>', {noremap = true})
vim.keymap.set('n', '<leader>fq', ':q!<cr>', {noremap = true})
vim.keymap.set('x', '<leader>dp', [["_do<esc>p]], {noremap = true})

-- options

local undodir = vim.fn.expand('~/.config/nvim/undo')

if vim.fn.isdirectory(undodir) == 0 then
  vim.fn.mkdir(undodir, 'p')
end

vim.o.clipboard = 'unnamedplus'
vim.o.undofile = true
vim.o.undodir = vim.fn.expand('~/.config/nvim/undo')
vim.o.undolevels = 10000
vim.o.hlsearch = false
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.completeopt = 'menu'
vim.wo.number = true
vim.wo.relativenumber = true
vim.wo.scrolloff = 8
vim.wo.wrap = false
vim.o.tabstop = 4
vim.o.shiftwidth = 4
vim.o.expandtab = true

vim.g.python_recommended_style = 0

vim.api.nvim_create_autocmd('FileType', {
  pattern = 'python',
  callback = function()
    vim.api.nvim_buf_set_keymap(0, 'n', '<C-j>', ':w<CR>:!python %<CR>', {noremap = true})
  end,
})

vim.api.nvim_create_autocmd('FileType', {
	pattern = "*.lean",
	callback = function()
		vim.api.nvim_buf_set_keymap(0, 'n', '<C-j>', ':w<CR>:!lean %<CR>', {noremap = true})
	end,
})

vim.api.nvim_create_autocmd({"BufRead", "BufNewFile"}, {
	pattern = "*.mojo",
	command = "set filetype=python",
})

vim.api.nvim_create_autocmd({"BufEnter"}, {
  pattern = "*",
  callback = function()
    local first_line = vim.api.nvim_buf_get_lines(0, 0, 1, false)[1]
    if first_line and first_line:match("^-%[ RECORD 1 %]-------------------------") then
      vim.bo.filetype = 'sql_records'
    end
  end,
})

-- plugins

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end

vim.opt.rtp:prepend(lazypath)
local plugins = {
	{
		"nvim-treesitter/nvim-treesitter",
		run = ":TSUpdate"
	},
	{
		"Vimjas/vim-python-pep8-indent"
	},
	{
		'nvim-telescope/telescope.nvim',
		tag = '0.1.6',
		dependencies = { 'nvim-lua/plenary.nvim' }
	},
	{
		"EdenEast/nightfox.nvim",
		config = function() 
			vim.cmd("colorscheme carbonfox")
		end
	},
	{'neovim/nvim-lspconfig'},
	{
		'Julian/lean.nvim',
		event = { 'BufReadPre *.lean', 'BufNewFile *.lean' },

		dependencies = {
			'neovim/nvim-lspconfig',
			'nvim-lua/plenary.nvim',
			-- you also will likely want nvim-cmp or some completion engine
		},

		-- see details below for full configuration options
		opts = {
			lsp = {},
			mappings = true,
		}
	}
}

require("lazy").setup(plugins)

local builtin = require('telescope.builtin')

vim.keymap.set('n', '<leader>ff', builtin.find_files, {})
vim.keymap.set('n', '<leader>fg', builtin.live_grep, {})
vim.keymap.set('n', '<leader>fb', builtin.buffers, {})
vim.keymap.set('n', '<leader>fh', builtin.help_tags, {})

require('nvim-treesitter.configs').setup {
  ensure_installed = { "python", "cpp", "javascript", "typescript" },
  auto_install = true,
  highlight = {
    enable = true,
    additional_vim_regex_highlighting = false,
	link = {
		mojo = "python"
	}
  },
}

-- lsps

local lspconfig = require("lspconfig")

local on_lsp_attach = function(client, bufnr)
	print("LSP started.")
	vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')

	local opts = {noremap=true, silent=true}
	local map = function(key, command)
		vim.api.nvim_buf_set_keymap(bufnr, 'n', key, command, opts)
	end
	
	map('gD', '<Cmd>lua vim.lsp.buf.declaration()<CR>')
	map('gd', '<Cmd>lua vim.lsp.buf.definition()<CR>')
	map('K', '<Cmd>lua vim.lsp.buf.hover()<CR>')
	map('gi', '<Cmd>lua vim.lsp.buf.implementation()<CR>')
	map('<c-k>', '<Cmd> lua vim.lsp.buf.signature_help()<CR>')
	map('<leader>D', '<Cmd>lua vim.lsp.buf.type_definition()<CR>')
	map('gr', '<Cmd>lua vim.lsp.buf.references()<CR>')
	map('<leader>d', '<Cmd>lua vim.diagnostic.open_float()<CR>')
	map('[d', '<Cmd>lua vim.diagnostic.goto_prev()<CR>')
	map(']d', '<Cmd>lua vim.diagnostic.goto_next()<CR>')
	map('<leader>f', '<Cmd>lua vim.lsp.buf.formatting()<CR>')

	vim.api.nvim_buf_set_keymap(bufnr, 'i', '<c-k>', '<Cmd>lua vim.lsp.buf.hover()<CR>', opts)
end

-- lspconfig.basedpyright.setup{
-- 	on_attach = on_lsp_attach,
-- }

lspconfig.pylsp.setup{
  on_attach = on_lsp_attach,
  cmd = {"pylsp", "-vvv", "--log-file", "/tmp/lsp.log"},
	settings = {
		pylsp = {
			plugins = {
				pylsp_mypy = {
					enabled = true,
					live_mode = true,
				},
			}
		},
	}
}

local util = require("lspconfig.util")

lspconfig.sqlls.setup{
	on_attach = on_lsp_attach,
	cmd = {"sql-language-server", "up", "--method", "stdio"},
	filetypes = {"sql", "mysql"},
	root_dir = util.root_pattern(".sqllsrc.json")
}

lspconfig.ts_ls.setup{
	on_attach = on_lsp_attach,
	filetypes = { "javascript", "javascriptreact", "javascript.jsx", "typescript", "typescriptreact", "typescript.tsx" },
	init_options = {
		hostInfo = "neovim"
	}
}

vim.lsp.handlers["textDocument/publishDiagnostics"] = vim.lsp.with(
  vim.lsp.diagnostic.on_publish_diagnostics, {
    virtual_text = true,
    signs = true,
    update_in_insert = true,
  }
)
