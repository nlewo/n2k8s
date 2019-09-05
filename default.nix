let
  sources = import ./nix/sources.nix;
  nciOverlay = import (sources.nix-container-images + /overlay.nix);
  pkgs = import sources.nixpkgs { overlays = [ nciOverlay ]; };
 
  entrypoint = pkgs.stdenv.mkDerivation {
    name = "entrypoint";
    unpackPhase = ":";
    buildInputs = [ pkgs.makeWrapper ];
    installPhase = "install -m755 -D ${./entrypoint.sh} $out/bin/entrypoint";
    postFixup = ''
      wrapProgram $out/bin/entrypoint  --prefix PATH ":" ${pkgs.stdenv.lib.makeBinPath [ pkgs.coreutils pkgs.nix pkgs.skopeo pkgs.findutils pkgs.awscli ]}
    '';
  };
in

pkgs.lib.makeImage {
  config = {
    image = {
      name = "n2k8s";
      tag = "latest";
      run = ''
        ln -s ${entrypoint}/bin/entrypoint entrypoint
      '';
    };
    environment.systemPackages = [
      pkgs.coreutils
      # Seems to be required by the evaluator :/
      pkgs.gnutar pkgs.gzip
    ];
    nix = {
      enable = true;
      useSandbox = false;
    };
  };
}

