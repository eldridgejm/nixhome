import argparse
import pathlib
import typing
import socket
import subprocess
import os

import yaml


NIXHOME_DIRECTORY = pathlib.Path.home() / '.nixhome'
CONFIG_FILENAME = 'config.yaml'


def null_callback(*args, **kwargs):
    pass


class Config(typing.NamedTuple):
    metapackages: typing.Mapping[str, typing.List[str]]
    machines: typing.Mapping[str, typing.List[str]]


def read_config(stream):
    config = yaml.load(stream, Loader=yaml.Loader)
    return Config(**config)


def expand_metapackage_directives(metapackages, directives):
    packages = []
    for directive in directives:
        if directive.startswith('meta:'):
            metapackage_name = directive.split(':', 1)[1]
            for package in metapackages[metapackage_name]:
                packages.append(package)
        else:
            packages.append(directive)
    return packages


def make_nix_environment_file(packages, machine):
    """Generates a nix file that will install all requested packages."""
    commands = []
    for package in packages:
        if package.startswith('./'):
            # only install if there are nix instructions present
            if (NIXHOME_DIRECTORY / package[2:] / 'nix').is_dir():
                command = f'(import {package}/nix)'
                commands.append(command)
        else:
            command = f'pkgs.{package}'
            commands.append(command)
            
    default_nix = """
    let 
      pkgs = import <nixpkgs> {};
    in rec {

      nixhome-MACHINE = pkgs.buildEnv {
        name = "nixhome-MACHINE";
        paths = [
          COMMANDS
        ];
      };

    }
    """.replace("MACHINE", machine).replace("COMMANDS", '\n\t  '.join(commands))
    return default_nix


def create_directories(packages, on_create=null_callback):
    for package in packages:
        if package.startswith('./'):
            cwd = NIXHOME_DIRECTORY / package
            if (cwd / 'directories').exists():
                with (cwd / 'directories').open() as fileobj:
                    for line in fileobj:
                        path = pathlib.Path().home() / line.strip()
                        on_create(path)
                        path.mkdir(parents=True, exist_ok=True)


def stow_dotfiles(packages, on_stow=null_callback):
    for package in packages:
        if package.startswith('./'):
            cwd = NIXHOME_DIRECTORY / package
            if (cwd / 'dotfiles').is_dir():
                on_stow(cwd)
                subprocess.run('stow --target ~ dotfiles', shell=True, cwd=cwd)


def rebuild_nix_environment(
        packages, hostname, 
        on_before_install=null_callback,
        on_install=null_callback
        ):
    default_nix = make_nix_environment_file(packages, hostname)
    default_nix_path = NIXHOME_DIRECTORY / 'default.nix.tmp'

    on_before_install(default_nix)

    try:
        with default_nix_path.open('w') as fileobj:
            fileobj.write(default_nix)

        on_install()
        subprocess.run(
                f'nix-env -f default.nix.tmp -iA nixhome-{hostname}',
                shell=True,
                cwd=NIXHOME_DIRECTORY
                )
    except Exception:
        raise
    else:
        default_nix_path.unlink()


def clean_stowed_symlinks(path, max_depth=4):
    """Remove all symlinks back to the .nixhome directory"""
    if max_depth <= 0:
        return
    for subpath in path.glob('*'):
        if os.path.islink(subpath) and (NIXHOME_DIRECTORY in subpath.resolve().parents):
            print('Removed symlink at', subpath)
            os.unlink(subpath)
        elif subpath.is_dir():
            clean_stowed_symlinks(subpath, max_depth=max_depth-1)


def cmd_install(args):
    """CLI command to install dotfiles and rebuild nix environment."""
    with (NIXHOME_DIRECTORY / CONFIG_FILENAME).open() as fileobj:
        config = read_config(fileobj)

    hostname = socket.gethostname()
    directives = config.machines[hostname]['packages']
    packages = expand_metapackage_directives(config.metapackages, directives)

    def print_stowing(cwd):
        print(f'Stowing {cwd}')

    def on_before_install(default_nix):
        print('Generated default.nix:')
        print(default_nix)

    def on_install():
        print(f'Running nix-env -f default.nix.tml -iA nixhome-{hostname}')

    def on_create(directory):
        print(f"Creating directory {directory}")

    create_directories(packages, on_create=on_create)
    stow_dotfiles(packages, on_stow=print_stowing)
    rebuild_nix_environment(
        packages, hostname, 
        on_before_install=on_before_install, on_install=on_install
    )


def cmd_clean(args):
    clean_stowed_symlinks(pathlib.Path.home())


def main():
    parser = argparse.ArgumentParser()
    subparsers = parser.add_subparsers()

    parser_install = subparsers.add_parser('install')
    parser_install.set_defaults(cmd=cmd_install)

    parser_clean = subparsers.add_parser('clean')
    parser_clean.set_defaults(cmd=cmd_clean)

    args = parser.parse_args()
    if hasattr(args, 'cmd'):
        args.cmd(args)
    else:
        parser.print_help()


if __name__ == '__main__':
    main()
