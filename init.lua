-- Providers {{{

-- turn off unused providers
vim.g.loaded_node_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_python3_provider = 0
vim.g.loaded_ruby_provider = 0

-- }}}

-- Options {{{

local o = vim.o

o.ignorecase = true
o.smartcase = true

o.foldmethod = 'marker'

o.tabstop = 4
o.softtabstop = 4
o.shiftwidth = 4
o.expandtab = true

o.mouse = ''

-- turn off splash screen
vim.opt.shortmess:append('I')

-- don't wrap long lines
o.wrap = false

-- show some hidden chars
o.list = true
vim.opt.listchars = { tab = '··', trail = '·', extends = '❯', precedes = '❮', nbsp = '×' }

-- line wrap marker
o.showbreak = '↪ '

o.cursorline = true

o.termguicolors = true

-- remove noisy | char from vertical split bars
vim.opt.fillchars:append({ vert = ' ' })

-- use system clipboard as default register
o.clipboard = 'unnamedplus'

-- keep the sign column from popping in and out with LSP diagnostics
o.signcolumn = 'yes'

-- completion menu behaviour (used by native LSP completion)
o.completeopt = 'menu,menuone,noinsert,fuzzy,popup'

-- rounded borders for hover/diagnostic floating windows
o.winborder = 'rounded'

-- lualine already shows the mode
o.showmode = false

-- persistent undo in the default location (~/.local/state/nvim/undo)
o.undofile = true

-- }}}

-- Autocmds {{{

local aug = vim.api.nvim_create_augroup('personal', { clear = true })

-- don't continue comment on o/O; ftplugins keep adding 'o' back,
-- so strip it for every filetype
vim.api.nvim_create_autocmd('FileType', {
    group = aug,
    callback = function()
        vim.opt_local.formatoptions:remove('o')
    end,
})

-- use tabs for indentation in Go sources, and don't render them as hidden chars
vim.api.nvim_create_autocmd('FileType', {
    group = aug,
    pattern = 'go',
    callback = function()
        vim.opt_local.expandtab = false
        vim.opt_local.listchars = { tab = '  ', trail = '·', extends = '❯', precedes = '❮', nbsp = '×' }
    end,
})

-- flash yanked text
vim.api.nvim_create_autocmd('TextYankPost', {
    group = aug,
    callback = function()
        vim.hl.on_yank()
    end,
})

-- }}}

-- Mappings {{{

local map = vim.keymap.set

-- tabs and buffers manipulations
map('n', '<Leader>[', '<Cmd>tabprevious<CR>')
map('n', '<Leader>]', '<Cmd>tabnext<CR>')
map('n', '<Leader>_', '<Cmd>bdelete<CR>')
map('n', '<Leader>+', '<Cmd>write<CR><Cmd>bdelete<CR>')

-- don't interrupt v-mode due indent
map('x', '<', '<gv')
map('x', '>', '>gv')

-- move rows (:move keeps registers and clipboard untouched)
map('n', '<C-k>', '<Cmd>move .-2<CR>==')
map('n', '<C-j>', '<Cmd>move .+1<CR>==')
map('x', '<C-k>', ":move '<-2<CR>gv=gv", { silent = true })
map('x', '<C-j>', ":move '>+1<CR>gv=gv", { silent = true })

-- center view on search result
for _, lhs in ipairs({ 'n', 'N', '*', '#', 'g*', 'g#' }) do
    map('n', lhs, lhs .. 'zz')
end

-- don't skip wrap lines due up/down movements, unless a count is given
map({ 'n', 'x' }, 'j', "v:count == 0 ? 'gj' : 'j'", { expr = true })
map({ 'n', 'x' }, 'k', "v:count == 0 ? 'gk' : 'k'", { expr = true })

-- file tree
map('n', '<BS>', '<Cmd>NvimTreeToggle<CR>')
map('n', '<Leader><BS>', '<Cmd>NvimTreeFindFile<CR>')

-- fuzzy finding
map('n', '<Leader>ff', '<Cmd>FzfLua files<CR>')
map('n', '<Leader>fc', '<Cmd>FzfLua git_bcommits<CR>')
map('n', '<Leader>fC', '<Cmd>FzfLua git_commits<CR>')
map('n', '<Leader>fb', '<Cmd>FzfLua buffers<CR>')
map('n', '<Leader>fg', '<Cmd>FzfLua live_grep<CR>')

-- }}}

-- Plugins {{{

-- bootstrap lazy.nvim
local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'
if not vim.uv.fs_stat(lazypath) then
    vim.fn.system({
        'git', 'clone', '--filter=blob:none', '--branch=stable',
        'https://github.com/folke/lazy.nvim.git', lazypath,
    })
end
vim.opt.rtp:prepend(lazypath)

require('lazy').setup({
    {
        'silentium-theme/silentium.nvim',
        priority = 1000,
        config = function()
            local silentium = require('silentium')
            silentium.setup({ accent = silentium.colors.light_gray })
            vim.cmd.colorscheme('silentium')
            -- upstream bug: silentium sets g:colors_name before :hi clear,
            -- which immediately unsets it again
            vim.g.colors_name = 'silentium'
        end,
    },

    {
        'nvim-tree/nvim-tree.lua',
        cmd = { 'NvimTreeToggle', 'NvimTreeFindFile' },
        opts = {
            on_attach = function(bufnr)
                local api = require('nvim-tree.api')
                api.config.mappings.default_on_attach(bufnr)
                -- nvim-tree maps <BS> to "close directory" in its window;
                -- keep the NERDTree-style toggle working inside the tree too
                vim.keymap.set('n', '<BS>', api.tree.close, { buffer = bufnr, desc = 'Close tree' })
                vim.keymap.set('n', 't', api.node.open.tab, { buffer = bufnr, desc = 'Open in new tab' })
            end,
            view = { width = 60 },
            renderer = {
                icons = {
                    -- no Nerd Font glyphs: plain unicode fold arrows only
                    glyphs = { folder = { arrow_closed = '+', arrow_open = '-' } },
                    show = { file = false, folder = false, git = false },
                },
            },
            actions = { open_file = { quit_on_open = true } },
        },
    },

    {
        'nvim-lualine/lualine.nvim',
        opts = {
            options = {
                -- disables all the fancy symbols to keep it simple and font independent
                icons_enabled = false,
                section_separators = '',
                component_separators = '',
            },
        },
    },

    'tpope/vim-fugitive',
    'tpope/vim-eunuch',
    'tpope/vim-sleuth',

    {
        'ibhagwan/fzf-lua',
        cmd = 'FzfLua',
        -- install --bin downloads a prebuilt fzf binary, no compiler needed
        dependencies = { { 'junegunn/fzf', build = './install --bin' } },
        opts = {
            winopts = {
                width = 1.0,
                border = "none",
                fullscreen = true,
                preview = {
                    border = "none",
                    winopts = {
                        number = false,
                    },
                },
            },
        },
    },

    'neovim/nvim-lspconfig',

    { 'aklt/plantuml-syntax', ft = 'plantuml' },
    { 'diepm/vim-rest-console', ft = 'rest' },
}, {
    install = { colorscheme = { 'silentium' } },
    change_detection = { notify = false },
    -- none of the plugins need luarocks
    rocks = { enabled = false },
})

-- }}}

-- LSP {{{

-- carried over from coc-settings.json
vim.lsp.config('ts_ls', {
    init_options = { disableAutomaticTypingAcquisition = true },
})

-- the config is shared between machines with different toolsets,
-- so enable a server only where its binary exists
local servers = {
    ts_ls = 'typescript-language-server',
    gopls = 'gopls',
    terraformls = 'terraform-ls',
}
for server, bin in pairs(servers) do
    if vim.fn.executable(bin) == 1 then
        vim.lsp.enable(server)
    end
end

vim.diagnostic.config({ virtual_text = true })

vim.api.nvim_create_autocmd('LspAttach', {
    group = aug,
    callback = function(ev)
        local opts = { buffer = ev.buf, silent = true }

        -- GoTo code navigation
        map('n', 'gd', vim.lsp.buf.definition, opts)
        map('n', 'gy', vim.lsp.buf.type_definition, opts)
        map('n', 'gi', vim.lsp.buf.implementation, opts)
        map('n', 'gr', vim.lsp.buf.references, opts)

        -- code actions for the current line / apply AutoFix
        map('n', '<Leader>ac', vim.lsp.buf.code_action, opts)
        map('n', '<Leader>qf', function()
            vim.lsp.buf.code_action({ context = { only = { 'quickfix' } }, apply = true })
        end, opts)

        -- completion as you type
        local client = vim.lsp.get_client_by_id(ev.data.client_id)
        if client and client:supports_method('textDocument/completion') then
            vim.lsp.completion.enable(true, client.id, ev.buf, { autotrigger = true })
        end
    end,
})

-- }}}
