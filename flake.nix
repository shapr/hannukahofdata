{
  description = "hannukahofdata";

  inputs = {
    # Nix Inputs
    nixpkgs.url = github:nixos/nixpkgs/nixos-unstable;
    flake-utils.url = github:numtide/flake-utils;
    pre-commit-hooks.url = github:cachix/pre-commit-hooks.nix;
    pre-commit-hooks.inputs.flake-utils.follows = "flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    pre-commit-hooks,
    flake-utils,
  }: let
    utils = flake-utils.lib;
    # htomlOverlay = (final: prev:
    #   {
    #     haskellPackages = prev.haskellPackages.override  {
    #       overrides = hfinal: hprev:
    #         {
    #           htoml =
    #             let patch = prev.fetchpatch {
    #                   url = "https://github.com/mirokuratczyk/htoml/compare/f776a75eda018b6885bfc802757cd3ea3d26c7d7..33971287445c5e2531d9605a287486dfc3cbe1da";
    #                   sha256 = "1111111111111111111111111111111111111111111111111111";
    #                 };
    #             in prev.haskell.lib.appendPatch hprev.htoml patch;
    #         };
    #     };
    #   });
  in
    utils.eachDefaultSystem (system: let
      compilerVersion = "ghc924";
      pkgs = nixpkgs.legacyPackages.${system};

      # random hacks, can I just do the same thing again?
      # hsPkgsBefore = pkgs.haskell.packages.${compilerVersion}.override {
      #   overrides = hfinal: hprev: {
      #     htoml =
      #       let patch = hprev.fetchpatch {
      #             url = "https://github.com/mirokuratczyk/htoml/compare/f776a75eda018b6885bfc802757cd3ea3d26c7d7..33971287445c5e2531d9605a287486dfc3cbe1da";
      #             sha256 = "1111111111111111111111111111111111111111111111111111";
      #           };
      #       in hprev.haskell.lib.appendPatch hprev.htoml patch;
      #   };
      # };
      hsPkgs = pkgs.haskell.packages.${compilerVersion}.override {
        overrides = hfinal: hprev: {
          hannukahofdata = hfinal.callCabal2nix "hannukahofdata" ./. {};
        };
      };
    in rec {
      packages =
        utils.flattenTree
        {hannukahofdata = hsPkgs.hannukahofdata;};

      # nix flake check
      checks = {
        pre-commit-check = pre-commit-hooks.lib.${system}.run {
          src = ./.;
          hooks = {
            alejandra.enable = true;
            fourmolu.enable = true;
            cabal-fmt.enable = true;
          };
        };
      };

      # nix develop
      devShell = hsPkgs.shellFor {
        inherit (self.checks.${system}.pre-commit-check) shellHook;
        withHoogle = true;
        packages = p: [
          p.hannukahofdata
        ];
        buildInputs = with pkgs;
          [
            hsPkgs.haskell-language-server
            haskellPackages.cabal-install
            cabal2nix
            haskellPackages.ghcid
            haskellPackages.fourmolu
            haskellPackages.cabal-fmt
            nodePackages.serve
          ]
          ++ (builtins.attrValues (import ./scripts.nix {s = pkgs.writeShellScriptBin;}));
      };

      # nix build
      defaultPackage = packages.hannukahofdata;
    });
}
