{ config, lib, pkgs, ... }:

{
  home = {
    enableNixpkgsReleaseCheck = true;

    sessionVariables = {
      EDITOR = "nvim";
    };

    shellAliases = {
      rmd = "rm -rf";
      psa = "ps aux";
      l = "exa -F";
      t = "tmux attach-session";
      view = "nvim -R"; # programs.neovim can't symlink this.
      k = "kubectl";
    };

    packages = [
      # Kubernetes things
      pkgs.docker
      pkgs.kubectl
      pkgs.kubernetes-helm
      pkgs.kind

      # Rust things
      pkgs.rustc
      pkgs.cargo
    ];

    file = {
      hushlogin = {
        target = ".hushlogin";
        text = "";
      };
    };

    sessionPath = [ "$HOME/control/go/bin" ];

    stateVersion = "21.11";
  };

  programs = {
    zsh = {
      enable = true;
      dotDir = ".config/zsh";
      history.path = "${config.xdg.dataHome}/zsh/zsh_history";
      enableCompletion = true;
      enableAutosuggestions = true;
      enableSyntaxHighlighting = true;
      defaultKeymap = "emacs";
      plugins = [
        {
          name = "powerlevel10k";
          src = pkgs.zsh-powerlevel10k;
          file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
        }
        {
          name = "powerlevel10k-config";
          src = lib.cleanSource ./zsh;
          file = "p10k.zsh";
        }
        {
          name = "zsh-nix-shell";
          file = "nix-shell.plugin.zsh";
          src = pkgs.fetchFromGitHub {
            owner = "chisui";
            repo = "zsh-nix-shell";
            rev = "v0.5.0";
            sha256 = "0za4aiwwrlawnia4f29msk822rj9bgcygw6a8a6iikiwzjjz0g91";
          };
        }
      ];
      localVariables = {
        ZSH_AUTOSUGGEST_STRATEGY = [ "history" "completion" ];
      };
      initExtraBeforeCompInit = ''
        P10KP="$XDG_CACHE_HOME/p10k-instant-prompt-''${(%):-%n}.zsh"; [[ ! -r "$P10KP" ]] || source "$P10KP"
      '';
    };

    tmux = {
      enable = true;
      prefix = "C-a";
      terminal = "screen-256color";
      shell = "${pkgs.zsh}/bin/zsh";
      escapeTime = 0;
      newSession = true;
      extraConfig = ''
        bind-key A command-prompt 'rename-window "%%"'
        set -g renumber-windows on
        set -g visual-bell on
        set -g mouse off
        bind-key m run 'tmux show -g mouse | grep -q on && T=off || T=on;tmux set -g mouse $T;tmux display "Mouse $T"'
        unbind -Tcopy-mode-vi Enter
        bind-key -Tcopy-mode-vi 'v' send -X begin-selection
        bind-key | split-window -h
        bind-key \\ split-window -h 
        bind-key - split-window -v
        unbind '"'
        unbind %
        set -g status-interval 1
        set -g status-bg "#58a6ff"
        set -g status-fg "#ffffff"
        set -g status-left ' '
        set -g status-left-length 0
        set -g status-right ' '
        set -g status-right-length 0
        set-window-option -g window-status-current-style bold
        set-window-option -g window-status-current-format '#I #W '
        set-window-option -g window-status-format '#I #W '
        set -g pane-active-border-style fg=#58a6ff
      '';
    };

    neovim = {
      enable = true;
      viAlias = true;
      vimAlias = true;
      vimdiffAlias = true;
      coc = {
        enable = true;

        # TODO(negz): Remove this once coc-nvim is updated in nixpkgs to
        # 2022-05-21 or greater per https://github.com/nix-community/home-manager/issues/2966
        # https://github.com/NixOS/nixpkgs/blob/50bbd084/pkgs/applications/editors/vim/plugins/generated.nix#L1375
        package = pkgs.vimUtils.buildVimPluginFrom2Nix {
          pname = "coc.nvim";
          version = "2022-05-21";
          src = pkgs.fetchFromGitHub {
            owner = "neoclide";
            repo = "coc.nvim";
            rev = "791c9f673b882768486450e73d8bda10e391401d";
            sha256 = "sha256-MobgwhFQ1Ld7pFknsurSFAsN5v+vGbEFojTAYD/kI9c=";
          };
        };

        settings = {
          languageserver = {
            go = {
              command = "gopls";
              rootPatterns = [ "go.mod" ];
              filetypes = [ "go" ];
            };
          };
        };
      };
      extraPackages = [ pkgs.nodejs pkgs.gopls ]; # For CoC
      extraConfig = ''
        set hidden
        set autoindent
        set smartindent
        set showmatch
        set incsearch
        set noerrorbells
        set number
        set numberwidth=4
        set nowrap
        set showcmd
        set scrolloff=3
        set backspace=2
      '';
      plugins = with pkgs.vimPlugins;
        [
          vim-nix
          {
            plugin = gitsigns-nvim;
            config = ''
              lua << END
              require('gitsigns').setup()
              END
            '';
          }
          {
            plugin = pkgs.vimUtils.buildVimPluginFrom2Nix {
              name = "github-nvim-theme";
              src = pkgs.fetchFromGitHub {
                owner = "projekt0n";
                repo = "github-nvim-theme";
                rev = "v0.0.4";
                sha256 = "tnHbM/oUHd/lJmz8VDREWiIRjbnjRx1ZksNh534mqzc=";
              };
            };
            config = ''
              lua << END
              require('github-theme').setup {
                theme_style = "dark_default";
              }
              END
            '';
          }
          {
            plugin = lualine-nvim;
            config = ''
              lua << END
              require('lualine').setup {
                options = {
                  icons_enabled = false,
                  section_separators = ' ',
                  component_separators = ' ',
                }
              }
              END
            '';
          }
          {
            plugin = pkgs.vimUtils.buildVimPluginFrom2Nix {
              name = "auto-dark-mode";
              src = pkgs.fetchFromGitHub {
                owner = "f-person";
                repo = "auto-dark-mode.nvim";
                rev = "9a7515c180c73ccbab9fce7124e49914f88cd763";
                sha256 = "kPq/hoSn9/xaienyVWvlhJ2unDjrjhZKdhH5XkB2U0Q=";
              };
            };
            config = ''
              lua << END
              local auto_dark_mode = require('auto-dark-mode')
              auto_dark_mode.setup {
                set_dark_mode = function()
                  vim.api.nvim_set_option('background', 'dark')
                  vim.cmd('colorscheme github_dark_default')
                end,
                set_light_mode = function()
                  vim.api.nvim_set_option('background', 'light')
                  vim.cmd('colorscheme github_light_default')
                end,
              }
              auto_dark_mode.init()
              END
            '';
          }
        ];
    };

    ssh = {
      enable = true;
      forwardAgent = true;
    };

    git = {
      enable = true;
      userName = "Nic Cope";
      userEmail = "nicc@rk0n.org";
      aliases = {
        b = "branch";
        ca = "commit -a";
        co = "checkout";
        d = "diff";
        p = "status";
        ll = "log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold green)(%ar)%C(reset) %C(white)%s%C(reset) %C(dim white)- %an%C(reset)%C(auto)%d%C(reset)' --all";
      };
      ignores = [ ".DS_Store" ];
      extraConfig = {
        push = {
          default = "current";
        };
      };
    };

    exa = {
      enable = true;
      enableAliases = true;
    };

    go = {
      enable = true;
      package = pkgs.go_1_18;
      goPath = "control/go";
      goBin = "control/go/bin";
    };
  };
}
