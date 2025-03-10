{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  inputs.js2nix = {
    url = "github:canva-public/js2nix";
    flake = false;
  };

  outputs = { nixpkgs, js2nix, ... }:
    let
      supportedSystems = [ "x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      pkgs = forAllSystems (system: nixpkgs.legacyPackages.${system}.extend (self: super: {
        js2nix = self.callPackage js2nix { };
      }));
    in
    rec {
      packages = forAllSystems (system: {
        default =
          let
            env = pkgs.${system}.js2nix {
              package-json = ./package.json;
              yarn-lock = ./yarn.lock;
            };
          in
          env.pkgs."@anthropic-ai/claude-code";
      });

      devShells = forAllSystems (system: {
        default = builtins.trace (builtins.attrNames packages."aarch64-darwin") pkgs.${system}.mkShellNoCC {
          packages = with pkgs.${system}; [
            yarn
            packages.${system}.default
          ];
        };
      });
    };
}
