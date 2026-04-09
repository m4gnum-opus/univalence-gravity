# sim/prototyping/shell.nix
let
  # Pinning to NixOS 24.05 to guarantee environment stability
  pkgs = import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/nixos-24.05.tar.gz") {};
  
  # Explicitly requesting Python 3.12
  python = pkgs.python312.withPackages (ps: [
    ps.networkx
    ps.numpy
  ]);
in
pkgs.mkShell {
  buildInputs = [ python ];
  
  shellHook = ''
    echo "Univalence Gravity: Prototyping Oracle Environment"
    python --version
    echo "networkx version: $(python -c 'import networkx; print(networkx.__version__)')"
    echo "numpy version: $(python -c 'import numpy; print(numpy.__version__)')"
  '';
}