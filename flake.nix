{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  inputs.js2nix = {
    url = "github:canva-public/js2nix/8cd32b5c87767b019e0960b27599f6b9d195ddb0";
    flake = false;
  };

  outputs = { nixpkgs, js2nix, ... }:
    let
      supportedSystems = [ "x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      pkgs = forAllSystems (system: nixpkgs.legacyPackages.${system}.extend (self: super: {
        # Prevent the node-gyp from the nixpkgs to skim in the js2nix since it doesn't refer python3
        # See this https://github.com/canva-public/js2nix/blob/main/lib.nix#L15 which means it uses
        # the node-gyp from nixpkgs by default.
        js2nix = import js2nix {
          # Ensure we run python 3.10, because the distutils module that the node-gyp uses was
          # removed from python 3.12+
          python3 = self.python310;
          inherit (self)
            lib
            stdenv
            callPackage
            fetchurl
            makeWrapper
            writeScriptBin
            runCommand
            coreutils
            libarchive
            nodejs
            xcbuild
            nix
            yarn;
        };
      }));
    in
    rec {
      packages = forAllSystems
        (system:
          let
            env = pkgs.${system}.js2nix.buildEnv {
              package-json = ./package.json;
              yarn-lock = ./yarn.lock;
              overlays = [
                (self: super: {
                  "@github/copilot@0.0.328" = super."@github/copilot@0.0.328".overrideAttrs (x: { doCheck = false; });
                  "@napi-rs/keyring-freebsd-x64@1.1.9" = super."@napi-rs/keyring-freebsd-x64@1.1.9".override { doCheck = false; };
                  "@napi-rs/keyring-darwin-x64@1.1.9" = super."@napi-rs/keyring-darwin-x64@1.1.9".override { doCheck = false; };
                  "@napi-rs/keyring-linux-arm-gnueabihf@1.1.9" = super."@napi-rs/keyring-linux-arm-gnueabihf@1.1.9".override { doCheck = false; };
                  "@napi-rs/keyring-linux-arm64-gnu@1.1.9" = super."@napi-rs/keyring-linux-arm64-gnu@1.1.9".override { doCheck = false; };
                  "@napi-rs/keyring-linux-riscv64-gnu@1.1.9" = super."@napi-rs/keyring-linux-riscv64-gnu@1.1.9".override { doCheck = false; };
                  "@napi-rs/keyring-linux-arm64-musl@1.1.9" = super."@napi-rs/keyring-linux-arm64-musl@1.1.9".override { doCheck = false; };
                  "@napi-rs/keyring-linux-x64-musl@1.1.9" = super."@napi-rs/keyring-linux-x64-musl@1.1.9".override { doCheck = false; };
                  "@napi-rs/keyring-linux-x64-gnu@1.1.9" = super."@napi-rs/keyring-linux-x64-gnu@1.1.9".override { doCheck = false; };
                  "@napi-rs/keyring-win32-arm64-msvc@1.1.9" = super."@napi-rs/keyring-win32-arm64-msvc@1.1.9".override { doCheck = false; };
                  "@napi-rs/keyring-win32-ia32-msvc@1.1.9" = super."@napi-rs/keyring-win32-ia32-msvc@1.1.9".override { doCheck = false; };
                  "@napi-rs/keyring-win32-x64-msvc@1.1.9" = super."@napi-rs/keyring-win32-x64-msvc@1.1.9".override { doCheck = false; };
                  "@napi-rs/keyring-win32-x64-gnu@1.1.9" = super."@napi-rs/keyring-win32-x64-gnu@1.1.9".override { doCheck = false; };
                })
              ];
            };
          in
          {
            claude = env.pkgs."@anthropic-ai/claude-code";
            amp = env.pkgs."@sourcegraph/amp";
            copilot = env.pkgs."@github/copilot";
          }
        );

      devShells = forAllSystems (system: {
        default = builtins.trace (builtins.attrNames packages."aarch64-darwin") pkgs.${system}.mkShellNoCC {
          packages = (with pkgs.${system}; [
            yarn
            pkgs.${system}.js2nix.bin
          ]) ++ (with packages.${system}; [
            claude
            amp
            copilot
          ]);
        };
      });
    };
}
