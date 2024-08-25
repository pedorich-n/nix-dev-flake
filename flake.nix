{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    flake-parts.url = "github:hercules-ci/flake-parts";

    extra-config.url = "github:pedorich-n/nix-dev-flake/extra-config?dir=extra-config";

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
    systems = import systems;
    imports = [
      inputs.treefmt-nix.flakeModule
      inputs.pre-commit-hooks.flakeModule
      "${inputs.extra-config}/config.nix"
    ];

    perSystem = { config, lib, ... }: {
      devShells = {
        pre-commit = config.pre-commit.devShell;
      };

      treefmt.config = {
        projectRootFile = ".root";
        flakeCheck = false;

        programs = {
          # Nix
          nixpkgs-fmt.enable = true;

          # Other
          prettier.enable = true;
        };
      };

      pre-commit.settings = {
        rootSrc = lib.mkForce ../.;

        hooks = {
          deadnix.enable = true;
          statix.enable = true;

          treefmt = {
            enable = true;
            package = config.treefmt.build.wrapper;
          };
        };
      };
    };

  };
}
