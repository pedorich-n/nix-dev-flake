{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    flake-parts.url = "github:hercules-ci/flake-parts";

    extra-config = {
      url = "path:./extra-config/config.nix";
      flake = false;
    };

    # Dev tools
    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
      };
    };

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
      };
    };
  };

  outputs = inputs@{ flake-parts, systems, ... }: flake-parts.lib.mkFlake { inherit inputs; } {
    debug = true;

    systems = import systems;
    imports = [
      inputs.treefmt-nix.flakeModule
      inputs.pre-commit-hooks.flakeModule
      inputs.extra-config.outPath
    ];

    perSystem = { config, lib, ... }: {
      devShells = {
        pre-commit = config.pre-commit.devShell;
      };

      treefmt.config = {
        projectRootFile = lib.mkDefault ".root";
        flakeCheck = lib.mkDefault false;

        programs = {
          # Nix
          nixpkgs-fmt.enable = lib.mkDefault true;
          deadnix.enable = lib.mkDefault true;
          statix = {
            enable = lib.mkDefault true;
            disabled-lints = lib.mkDefault [
              # Replaces stuff like `map (x: double x) [ 1 2 3 ]` with `map double [ 1 2 3 ]`. I don't particularly like it. IMO explicit is better.
              "eta_reduction"
              # Replaces stuff like `mtl = pkgs.haskellPackages.mtl;` with `inherit (pkgs.haskellPackages) mtl;`. I find this sometimes confusing. IMO explicit is better.
              "manual_inherit_from"
            ];
          };

          # Just
          just.enable = lib.mkDefault true;

          # Shell
          shfmt.enable = lib.mkDefault true;

          # Other
          prettier.enable = lib.mkDefault true;
        };
      };

      pre-commit.settings = {
        # This value is already set in pre-commit module. Default prioriy is 100. lib.mkForce sets priority to 50.
        # So I need to use a value that's lover than default, but higher than 50, so that downstram lib.mkForce could be used if needed
        rootSrc = lib.mkOverride 95 ../.;

        hooks.treefmt = {
          enable = lib.mkDefault true;
          package = lib.mkDefault config.treefmt.build.wrapper;
        };
      };
    };

  };
}
