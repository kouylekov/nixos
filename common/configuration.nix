{ config, pkgs, lib, pkgs-matterhorn, ... }:

{
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Provide /bin/bash for scripts with #!/bin/bash shebangs
  system.activationScripts.binbash = lib.stringAfter [ "stdio" ] ''
    ln -sfn ${pkgs.bash}/bin/bash /bin/bash
  '';

  networking.networkmanager.enable = true;
  services.resolved.enable = true;

  time.timeZone = "Europe/Oslo";
  i18n.defaultLocale = "en_US.UTF-8";

  # Display manager
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
    theme = "sddm-astronaut-theme";
    extraPackages = [ pkgs.sddm-astronaut ];
  };

  # Override dbus-broker forced by UWSM — it can break SDDM activation
  services.dbus.implementation = lib.mkForce "dbus";

  services.gnome.gnome-keyring.enable = true;
  services.gnome.gcr-ssh-agent.enable = false;
  services.printing.enable = true;
  services.flatpak.enable = true;
  services.fwupd.enable = true;

  # Bluetooth
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

  # Audio
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  users.users.milen = {
    isNormalUser = true;
    description = "Milen Kouylekov";
    extraGroups = [ "networkmanager" "wheel" ];
  };

  # Home Manager
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.milen = import ./home.nix;
  };

  fonts.packages = with pkgs; [
    nerd-fonts.fira-code
    nerd-fonts.droid-sans-mono
    nerd-fonts.jetbrains-mono
    nerd-fonts.adwaita-mono
    nerd-fonts.bitstream-vera-sans-mono
    nerd-fonts.code-new-roman
    nerd-fonts.noto
    nerd-fonts.symbols-only
    nerd-fonts.terminess-ttf
    nerd-fonts.ubuntu
    nerd-fonts.ubuntu-mono
    nerd-fonts.ubuntu-sans
    nerd-fonts.sauce-code-pro
  ];

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    configure = {
      packages.myPlugins = with pkgs.vimPlugins; {
        start = [
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

          # Treesitter
          nvim-treesitter.withAllGrammars

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
      };
      customRC = ''
        lua << EOF
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
        vim.lsp.config['pyright'] = {
          cmd = { 'pyright-langserver', '--stdio' },
          filetypes = { 'python' },
          root_markers = { 'pyproject.toml', 'setup.py', 'setup.cfg', 'requirements.txt', '.git' },
          capabilities = capabilities,
          settings = {
            python = {
              pythonPath = vim.env.VIRTUAL_ENV and (vim.env.VIRTUAL_ENV .. '/bin/python') or nil,
              venvPath = vim.env.VIRTUAL_ENV and vim.fs.dirname(vim.env.VIRTUAL_ENV) or nil,
              venv = vim.env.VIRTUAL_ENV and vim.fs.basename(vim.env.VIRTUAL_ENV) or nil,
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
          python = { 'ruff', 'pylint' },
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
        EOF
      '';
    };
  };

  programs.dconf.enable = true;
  programs.git.enable = true;

  # SSH agent
  programs.ssh.startAgent = true;

  programs.hyprland = {
    enable = true;
    withUWSM = true;
    xwayland.enable = true;
  };

  programs.firefox.enable = true;

  # Podman
  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
    defaultNetwork.settings.dns_enabled = true;
  };
  nixpkgs.config.allowUnfree = true;

  # Nix settings
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  # Enable nix-ld for running dynamically linked executables (e.g., pre-commit hooks)
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    # Add common libraries that dynamically linked executables might need
    stdenv.cc.cc.lib
    zlib
    openssl
  ];

  environment.systemPackages = with pkgs; [
    sddm-astronaut
    waybar
    fuzzel
    opencode
    alacritty
    xdg-desktop-portal-hyprland
    claude-code
    discord
    mumble
    teams-for-linux
    fastfetch
    python3
    go
    gcc

    # Neovim LSP servers
    pyright
    gopls
    golangci-lint-langserver
    golangci-lint

    # Neovim formatters
    stylua
    ruff

    # Neovim linters
    pylint

    # Neovim telescope dependencies
    ripgrep
    fd

    # Hyprland ecosystem
    hypridle
    hyprlock
    mako
    grim
    slurp
    wl-clipboard
    cliphist
    brightnessctl
    playerctl
    pavucontrol
    networkmanagerapplet
    blueman
    libnotify
    jq
    ranger

    # VPN
    sshuttle

    # Spell checking
    aspell
    aspellDicts.en

    # Dev tools
    gh
    gnupg
    pinentry-gnome3
    vault
    mise
    pre-commit
    openshift
    btop
    proton-pass-cli

    # Communication
    pkgs-matterhorn.matterhorn
    zoom-us
  ];

  system.stateVersion = "25.11";
}
