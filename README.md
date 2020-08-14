nixhome
=======

A *simple* declarative way to manage your environment with nix.

Installation
------------

Add the github repo to your system packages in `/etc/nixos/configuration.nix`:

```
  environment.systemPackages = with pkgs; [
    ...
    (import (builtins.fetchGit "https://github.com/eldridgejm/nixhome"))
    ...
  ];
```

Usage
-----

### Installing packages

In your home directory, create a folder named `.nixhome`, and within it a file
named `config.yaml` that looks like this:


```
machines:
    alamere:
        packages:
            - neovim
            - ripgrep
```

Run `nh install`. Now you have *ripgrep* and *neovim* installed in your user's
nix-profile.


### Tracking dotfiles

Suppose we want to include dotfiles for *neovim*. Create a directory with
whatever name you'd like under `.nixhome/`. It will contain your neovim
configuration, so `mkdir .nixhome/neovim` makes a lot of sense.

Now create a `dotfiles` directory within this new folder. This folder will be
*stowed* into your home directory using *GNU Stow*. Since neovim's configuration
is in `~/.config/nvim/init.vim`, place your configuration in
`.nixhome/neovim/dotfiles/.config/nvim/init.vim`.

Run `nh install`. Your dotfiles have been stowed.


### Customized packages

Suppose we want to customize neovim, perhaps by overriding some of the build
inputs. Or suppose we have a special package that isn't in the nix channels. In
either case, we can specify our customizations by writing a
`default.nix` file in `.nixhome/neovim/nix/`. We then update `config.yaml` so
that instead of installing the version of the package from nixpkgs, it installs
the local derivation. We do this by replacing `neovim` with `./neovim`.

For instance, to enable the "vim" alias for neovim, simply include this in
`.nixhome/neovim/nix/default.nix`:

```
with import <nixpkgs> {};

pkgs.neovim.override {
  vimAlias = true;
}
```

The `config.yaml` should become:


```
machines:
    alamere:
        packages:
            - ./neovim
            - ripgrep
```

Notice the dot-slash in `- ./neovim`!

### Metapackages

A metapackage is a collection of packages that are usually installed together;
e.g., a desktop environment that uses *bspwm* and *sxhkd* and *google-chrome*.

Metapackages are specified in `config.yaml`. For instance, to create a
metapackage named "gui":


```
metapackages:
    gui:
        - ./st
        - google-chrome
        - zathura
machines:
    alamere:
        user: eldridge
        packages:
            - meta:gui
            - ./neovim
            - ripgrep
```

This metapackage includes a local derivation of *st* (the simple terminal
emulator), and the nixpkgs versions of google-chrome and zathura.

To install the metapackage on a machine, include its named in the machine's
package list with a pre-pended `meta:`, as above.
