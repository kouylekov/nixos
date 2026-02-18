{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "nixos";
  networking.networkmanager.enable = true;

  time.timeZone = "Europe/Oslo";
  i18n.defaultLocale = "en_US.UTF-8";

  # Display manager
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
  };

  # AMD GPU
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  services.printing.enable = true;

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
        ];
      };
      customRC = ''
        lua << EOF
        -- Set leader key to space
        vim.g.mapleader = " "
        vim.g.maplocalleader = " "

        -- Telescope keymaps
        local builtin = require('telescope.builtin')
        vim.keymap.set('n', '<leader>ff', builtin.find_files, {})
        vim.keymap.set('n', '<leader>fg', builtin.live_grep, {})
        vim.keymap.set('n', '<leader>fb', builtin.buffers, {})
        vim.keymap.set('n', '<leader>fh', builtin.help_tags, {})

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
        vim.lsp.config['pyright'] = {
          cmd = { 'pyright-langserver', '--stdio' },
          filetypes = { 'python' },
          root_markers = { 'pyproject.toml', 'setup.py', 'setup.cfg', 'requirements.txt', '.git' },
          capabilities = capabilities,
        }
        vim.lsp.enable('pyright')

        -- LSP keymaps
        vim.keymap.set('n', 'gd', vim.lsp.buf.definition, {})
        vim.keymap.set('n', 'K', vim.lsp.buf.hover, {})
        vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, {})
        vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, {})
        vim.keymap.set('n', 'gr', vim.lsp.buf.references, {})
        EOF
      '';
    };
  };

  programs.git.enable = true;

  programs.hyprland = {
    enable = true;
    withUWSM = true;
    xwayland.enable = true;
  };

  programs.steam = {
    enable = true;
  };

  programs.firefox.enable = true;
  nixpkgs.config.allowUnfree = true;

  # Nix settings
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  environment.systemPackages = with pkgs; [
    waybar
    fuzzel
    alacritty
    xdg-desktop-portal-hyprland
    claude-code
    discord
    mumble
    teams-for-linux
    fastfetch
    python3
    pyright

    # Hyprland ecosystem
    hyprpaper           # wallpaper
    hypridle            # idle daemon
    hyprlock            # lock screen
    mako                # notifications
    grim                # screenshots
    slurp               # region selection
    wl-clipboard        # clipboard
    cliphist            # clipboard history
    brightnessctl       # brightness control
    playerctl           # media control
    pavucontrol         # audio control GUI
    networkmanagerapplet # network tray
    blueman             # bluetooth
    libnotify           # notify-send
    jq                  # JSON parsing for scripts
    ranger              # terminal file manager
  ];

  system.stateVersion = "25.11";

}
