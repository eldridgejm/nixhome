with import <nixpkgs> {};

python37Packages.buildPythonPackage {
  name = "nixhome";
  src = ./src;
  propagatedBuildInputs = with python37Packages; [ pyyaml stow git ];
}
