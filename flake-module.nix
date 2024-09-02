{ inputs, ... }:
{
  debug = true;

  imports = [
    inputs.treefmt-nix.flakeModule
    inputs.pre-commit-hooks.flakeModule
  ];

  perSystem = { config, lib, ... }: {
    devShells = {
      pre-commit = config.pre-commit.devShell;
    };

    treefmt.config = {
      projectRootFile = lib.mkDefault ".root"; # This one is used for real formatting because it runs outside of nix environment
      flakeCheck = lib.mkDefault true;

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

    pre-commit = {
      # Use treefmt's check script instead, since pre-commit only check staged files, which is confusing sometimes
      check.enable = lib.mkDefault false;
      settings = {
        hooks.treefmt = {
          enable = lib.mkDefault true;
          package = lib.mkDefault config.treefmt.build.wrapper;
        };
      };
    };
  };
}
