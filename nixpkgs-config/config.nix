{
  allowUnfree = true;
  pulseaudio = true;
  chromium.enablePepperPDF = true;

  packageOverrides = pkgs: let
    myVimBundle = let
      plugins = (pkgs.vimPlugins.override (old: { inherit (pkgs) python3; }));
    in with plugins; {
       # loaded on launch
       start = [
         fugitive
         rhubarb
         vim-grammarous
         vim-docbk
         vim-docbk-snippets
         UltiSnips
         vim-autoformat
         fzfWrapper
         vim-devicons
         nvim-completion-manager
         LanguageClient-neovim
         nvim-cm-racer
         airline
         nerdtree
         nerdtree-git-plugin
         colors-solarized
         ack-vim
         vim-go
         vim-polyglot
         ale
         # delimitMat
         editorconfig-vim
         ctrlp
         rust-vim
         vim-yapf
         vim-signify
         vim-nix
       ];
     };
   in {
    myVimBundle = myVimBundle;

    stable = import <stable> {};

    nur = pkgs.callPackage (import (builtins.fetchTarball {
      url = "https://github.com/nix-community/NUR/archive/master.tar.gz";
    })) {};

    cachix = pkgs.callPackage (import (builtins.fetchGit {
      url = "https://github.com/cachix/cachix";
      rev = "0c8366d2a901da28388680e891d4751255e79185";
    })) {};

    myvim = pkgs.neovim.override {
      vimAlias = true;
      withPython = true;
      configure = {
        customRC = ''
          if filereadable($HOME . "/.vimrc")
            source ~/.vimrc
          endif
          let $RUST_SRC_PATH = '${pkgs.rustPlatform.rustcSrc}'
          let g:grammarous#show_first_error = 1
        '';
        packages.nixbundle = myVimBundle;
      };
    };

    staging = pkgs.buildEnv {
      name = "staging";
      paths = [ ];
    };
  };
}
