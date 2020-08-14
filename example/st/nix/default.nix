# this packages st with some patches and my preferred font, Hack

with import <nixpkgs> {};


let
  st = pkgs.st.override {
    patches = [
      ./patches/st-scrollback-0.8.2.diff
      ./patches/colors.diff
      ./patches/font.diff
    ];
  };
in
  buildEnv {
    name = "st";
    paths = [ st hack-font ];
  }
