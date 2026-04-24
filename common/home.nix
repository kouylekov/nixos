{ config, pkgs, ... }:

{
  home.username = "milen";
  home.homeDirectory = "/home/milen";
  home.stateVersion = "25.11";

  # Dotfile management - symlink directly to repo for live editing
  xdg.configFile = let
    link = path: config.lib.file.mkOutOfStoreSymlink "/home/milen/nixos/config/${path}";
  in {
    "alacritty/alacritty.toml".source = link "alacritty/alacritty.toml";
    "ghostty/config".source = link "ghostty/config";
    "fuzzel/fuzzel.ini".source = link "fuzzel/fuzzel.ini";
    "hypr/hyprland.conf".source = link "hypr/hyprland.conf";
    "hypr/hypridle.conf".source = link "hypr/hypridle.conf";
    "hypr/hyprlock.conf".source = link "hypr/hyprlock.conf";
    "mako/config".source = link "mako/config";
    "waybar/config".source = link "waybar/config";
    "waybar/style.css".source = link "waybar/style.css";
    "matterhorn/config.ini".source = link "matterhorn/config.ini";
    "matterhorn/notify".source = link "matterhorn/notify";
  };

  # Classic cursor theme
  home.pointerCursor = {
    name = "Adwaita";
    package = pkgs.adwaita-icon-theme;
    size = 24;
    gtk.enable = true;
  };

  # Dark theme
  gtk = {
    enable = true;
    theme = {
      name = "Adwaita-dark";
      package = pkgs.gnome-themes-extra;
    };
    gtk4.theme = null;  # Use new default behavior instead of config.gtk.theme
  };

  dconf.settings."org/gnome/desktop/interface" = {
    color-scheme = "prefer-dark";
    text-scaling-factor = 1.25;
  };

  qt = {
    enable = true;
    platformTheme.name = "adwaita";
    style.name = "adwaita-dark";
  };

  programs.bash = {
    enable = true;
    initExtra = ''
      # Disable default venv prompt
      export VIRTUAL_ENV_DISABLE_PROMPT=1

      __git_branch() {
        local branch
        branch=$(git symbolic-ref --short HEAD 2>/dev/null) || return
        echo " ($branch)"
      }

      __venv_indicator() {
        if [ -n "$VIRTUAL_ENV" ]; then
          echo "(venv) "
        fi
      }

      PS1='\[\e[1;32m\]$(__venv_indicator)\[\e[0m\]\[\e[1;34m\]\W\[\e[33m\]$(__git_branch)\[\e[0m\]\$ '
      eval "$(/run/current-system/sw/bin/mise activate bash)"

      export PATH="/home/milen/.local/bin:$PATH"
      export VAULT_ADDR=https://vault.uio.no:8200
    '';
  };

  # Make fonts available in ~/.local/share/fonts for FHS-sandboxed apps (e.g. Horizon Client)
  home.file.".local/share/fonts/dejavu".source = "${pkgs.dejavu_fonts}/share/fonts/truetype";

  # Auto-mount removable media (USB drives, etc.)
  services.udiskie = {
    enable = true;
    notify = true;
    automount = true;
    tray = "never";  # no tray icon needed on Hyprland
  };

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    withPython3 = true;  # Required for Python LSP features
    withRuby = false;    # Not needed

    # Modern treesitter configuration
    treesitter = {
      enable = true;
      grammarPackages = with pkgs.vimPlugins.nvim-treesitter.builtGrammars; [
        bash
        nix
        python
        lua
        go
        markdown
        json
        yaml
        toml
        gitcommit
        gitignore
        vimdoc
        diff
      ];
    };

    plugins = with pkgs.vimPlugins; [
      # Telescope and dependencies
      telescope-nvim
      plenary-nvim

      # Autocompletion
      nvim-cmp
      cmp-nvim-lsp
      cmp-buffer
      cmp-path
      luasnip
      cmp_luasnip
      friendly-snippets

      # Formatting, linting, diagnostics
      conform-nvim
      nvim-lint
      trouble-nvim

      # Git
      gitsigns-nvim
      neogit
      diffview-nvim

      # UI
      nightfox-nvim
      lualine-nvim
      nvim-web-devicons
      nvim-colorizer-lua

      # Editing
      nvim-autopairs
    ];
    initLua = ''
      -- Set leader key to space
      vim.g.mapleader = " "
      vim.g.maplocalleader = " "

      -- Editor settings
      local o = vim.opt
      o.number = true
      o.relativenumber = true
      o.clipboard = 'unnamedplus'
      o.autoindent = true
      o.cursorline = true
      o.expandtab = true
      o.shiftwidth = 2
      o.tabstop = 2
      o.mouse = 'a'
      o.splitright = true
      o.splitbelow = true
      o.termguicolors = true
      o.spell = true
      o.spelllang = 'en_us'
      vim.diagnostic.config({ virtual_text = true })

      -- Code folding with treesitter
      o.foldmethod = 'expr'
      o.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
      o.foldlevel = 99
      o.foldlevelstart = 99
      o.foldenable = true
      o.foldcolumn = '1'

      -- Colorscheme
      require('nightfox').setup({ options = { transparent = true } })
      vim.cmd('colorscheme terafox')

      -- Statusline
      require('lualine').setup({
        options = {
          globalstatus = true,
          icons_enabled = true,
          component_separators = { left = '|', right = '|' },
          section_separators = { left = "", right = "" },
          theme = 'terafox',
        },
        sections = {
          lualine_a = { { 'mode', fmt = function(str) return ' ' .. str:sub(1, 1) .. ' ' end } },
          lualine_b = {
            { 'branch', icon = "" },
            { 'diff', symbols = { added = '+', modified = '~', removed = '-' } },
            'diagnostics',
          },
          lualine_c = { { 'filename', path = 1, symbols = { modified = ' ●', readonly = "" } } },
          lualine_x = { 'lsp_status', 'encoding', 'fileformat', 'filetype' },
          lualine_y = { 'progress', 'location' },
          lualine_z = { function() return ' ' .. os.date('%R') .. ' ' end },
        },
      })

      -- Git signs
      require('gitsigns').setup({
        signs = {
          add          = { text = '│' },
          change       = { text = '│' },
          delete       = { text = '_' },
          topdelete    = { text = '‾' },
          changedelete = { text = '~' },
          untracked    = { text = '┆' },
        },
        current_line_blame = false,
        current_line_blame_opts = { virt_text_pos = 'eol', delay = 1000 },
      })

      -- Neogit
      require('neogit').setup({})

      -- Autopairs
      require('nvim-autopairs').setup({ disable_filetype = { 'TelescopePrompt', 'vim' } })

      -- Colorizer (inline color preview)
      require('colorizer').setup({ '*' })

      -- Telescope keymaps
      local builtin = require('telescope.builtin')
      vim.keymap.set('n', '<leader>ff', builtin.find_files, {})
      vim.keymap.set('n', '<leader>fg', builtin.live_grep, {})
      vim.keymap.set('n', '<leader>fb', builtin.buffers, {})
      vim.keymap.set('n', '<leader>fh', builtin.help_tags, {})
      vim.keymap.set('n', '<leader>fs', builtin.git_status, {})
      vim.keymap.set('n', '<leader>fc', builtin.git_commits, {})

      -- Enable treesitter highlighting (grammars pre-compiled by Nix)
      vim.api.nvim_create_autocmd("FileType", {
        callback = function()
          pcall(vim.treesitter.start)
        end,
      })

      -- Autocompletion setup
      local cmp = require('cmp')
      local luasnip = require('luasnip')
      require('luasnip.loaders.from_vscode').lazy_load()

      cmp.setup {
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert({
          ['<C-b>'] = cmp.mapping.scroll_docs(-4),
          ['<C-f>'] = cmp.mapping.scroll_docs(4),
          ['<C-Space>'] = cmp.mapping.complete(),
          ['<C-e>'] = cmp.mapping.abort(),
          ['<CR>'] = cmp.mapping.confirm({ select = true }),
          ['<Tab>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then
              luasnip.expand_or_jump()
            else
              fallback()
            end
          end, { 'i', 's' }),
          ['<S-Tab>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then
              luasnip.jump(-1)
            else
              fallback()
            end
          end, { 'i', 's' }),
        }),
        sources = cmp.config.sources({
          { name = 'nvim_lsp' },
          { name = 'luasnip' },
          { name = 'buffer' },
          { name = 'path' },
        }),
      }

      -- LSP setup with completion capabilities (Neovim 0.11+ native API)
      local capabilities = require('cmp_nvim_lsp').default_capabilities()

      -- Pyright: type checking, hover, go-to-definition, references
      local venv = vim.env.VIRTUAL_ENV
      vim.lsp.config['pyright'] = {
        cmd = { 'pyright-langserver', '--stdio' },
        filetypes = { 'python' },
        root_markers = { 'pyproject.toml', 'setup.py', 'setup.cfg', 'requirements.txt', '.git' },
        capabilities = capabilities,
        settings = {
          python = {
            pythonPath = venv and (venv .. '/bin/python') or nil,
            venvPath = venv and vim.fs.dirname(venv) or nil,
            venv = venv and vim.fs.basename(venv) or nil,
            analysis = {
              autoSearchPaths = true,
              diagnosticMode = 'workspace',
              useLibraryCodeForTypes = true,
            },
          },
        },
      }
      vim.lsp.enable('pyright')

      -- Ruff: fast linting diagnostics and formatting via LSP
      vim.lsp.config['ruff'] = {
        cmd = { 'ruff', 'server' },
        filetypes = { 'python' },
        root_markers = { 'pyproject.toml', 'ruff.toml', '.ruff.toml' },
        capabilities = capabilities,
      }
      vim.lsp.enable('ruff')

      -- Formatting with conform.nvim (ruff replaces black + isort)
      local conform = require('conform')
      conform.setup({
        formatters_by_ft = {
          python = { 'ruff_format' },
          lua = { 'stylua' },
        },
      })

      -- Linting with nvim-lint (async, on save)
      local lint = require('lint')
      lint.linters_by_ft = {
        python = { 'ruff' },
      }
      vim.api.nvim_create_autocmd({ 'BufWritePost' }, {
        callback = function()
          lint.try_lint()
        end,
      })

      -- Diagnostics UI with trouble.nvim
      require('trouble').setup({})

      -- LSP keymaps
      vim.keymap.set('n', 'gd', vim.lsp.buf.definition, {})
      vim.keymap.set('n', 'K', vim.lsp.buf.hover, {})
      vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, {})
      vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, {})
      vim.keymap.set('n', 'gr', vim.lsp.buf.references, {})
      vim.keymap.set('n', '<leader>xx', '<cmd>Trouble diagnostics toggle<cr>', {})
      vim.keymap.set('n', '<leader>xq', '<cmd>Trouble quickfix toggle<cr>', {})
      vim.keymap.set('n', '<leader>lf', function()
        conform.format({ async = true, lsp_fallback = true })
      end, {})

      -- General keymaps
      vim.keymap.set('n', '<leader>w', '<cmd>update<cr>', { silent = true })
      vim.keymap.set('n', '<leader>q', '<cmd>q<cr>', { silent = true })
      vim.keymap.set('i', 'jk', '<esc>', { silent = true })
      vim.keymap.set('n', '<leader>o', '<cmd>vsplit<cr>', { silent = true })
      vim.keymap.set('n', '<leader>p', '<cmd>split<cr>', { silent = true })

      -- Window navigation
      vim.keymap.set('n', '<C-h>', '<C-w>h', { silent = true })
      vim.keymap.set('n', '<C-l>', '<C-w>l', { silent = true })
      vim.keymap.set('n', '<C-k>', '<C-w>k', { silent = true })
      vim.keymap.set('n', '<C-j>', '<C-w>j', { silent = true })

      -- Window resize
      vim.keymap.set('n', '<C-Left>', '<C-w><', { silent = true })
      vim.keymap.set('n', '<C-Right>', '<C-w>>', { silent = true })
      vim.keymap.set('n', '<C-Up>', '<C-w>+', { silent = true })
      vim.keymap.set('n', '<C-Down>', '<C-w>-', { silent = true })

      -- Neogit
      vim.keymap.set('n', '<leader>gg', '<cmd>Neogit<cr>', { silent = true })
    '';
  };

  programs.home-manager.enable = true;
}
