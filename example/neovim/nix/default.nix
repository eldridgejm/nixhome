with import <nixpkgs> {};

pkgs.neovim.override {
  vimAlias = true;
  configure = {
    # it seems that if we don't source our dotfile here, it won't be loaded!
    customRC = ''
      source ~/.config/nvim/init.vim
    '';
    plug.plugins = with pkgs.vimPlugins; [
      deoplete-jedi
      vim # this is actually the dracula colorscheme
      vimtex
      vim-fish
      vim-vinegar
      vim-nix
    ];
  };
}
