{
  description = "NixOS configuration with flakes";

  nixConfig.extra-substituters = [
    #"https://mic92.cachix.org"
    "https://cache.thalheim.io"
  ];
  nixConfig.extra-trusted-public-keys = [
    "cache.thalheim.io-1:R7msbosLEZKrxk/lKxf9BTjOOH7Ax3H0Qj0/6wiHOgc="
    #"mic92.cachix.org-1:gi8IhgiT3CYZnJsaW7fxznzTkMUOn1RY4GmXdT/nXYQ="
  ];

  # To update all inputs:
  # $ nix flake update
  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";

    nix-index-database.url = "github:nix-community/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";

    nixos-generators = {
      #url = "github:nix-community/nixos-generators";
      url = "github:Mic92/nixos-generators/fedf7136f27490402fe8ab93e67fafae80513e9b";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixpkgs.url = "github:Mic92/nixpkgs/main";
    # for development
    #nixpkgs.url = "/home/joerg/git/nixpkgs";
    nur.url = "github:nix-community/NUR";
    # for development
    #sops-nix.url = "/home/joerg/git/sops-nix";
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    sops-nix.inputs.nixpkgs-stable.follows = "";

    bme680-mqtt.url = "github:Mic92/bme680-mqtt";
    bme680-mqtt.inputs.flake-parts.follows = "flake-parts";
    bme680-mqtt.inputs.nixpkgs.follows = "nixpkgs";

    bing-gpt-server.url = "github:Mic92/bing-gpt-server";
    bing-gpt-server.inputs.flake-parts.follows = "flake-parts";
    bing-gpt-server.inputs.nixpkgs.follows = "nixpkgs";

    retiolum.url = "git+https://git.thalheim.io/Mic92/retiolum";

    nixos-hardware.url = "github:NixOS/nixos-hardware";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    astro-nvim.url = "github:AstroNvim/AstroNvim";
    astro-nvim.flake = false;

    flake-registry.url = "github:NixOS/flake-registry";
    flake-registry.flake = false;

    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    srvos.url = "github:numtide/srvos";
    srvos.inputs.nixpkgs.follows = "nixpkgs";

    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";

    lanzaboote.url = "github:nix-community/lanzaboote";
    lanzaboote.inputs.flake-compat.follows = "";
    #lanzaboote.inputs.nixpkgs.follows = "nixpkgs";

    fast-flake-update.url = "github:Mic92/fast-flake-update";
    fast-flake-update.inputs.nixpkgs.follows = "nixpkgs";
    fast-flake-update.inputs.flake-parts.follows = "flake-parts";
    fast-flake-update.inputs.treefmt-nix.follows = "treefmt-nix";
  };

  outputs = inputs @ { self, flake-parts, nixpkgs, ... }:
    (flake-parts.lib.evalFlakeModule
      { inherit inputs; }
      {
        imports = [
          ./nixos/flake-module.nix
          ./nixos/images/flake-module.nix
          ./home-manager/flake-module.nix
          ./terraform/flake-module.nix
          ./devshell/flake-module.nix
        ];
        systems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" ];
        perSystem = { config, inputs', ... }: {
          # make pkgs available to all `perSystem` functions
          _module.args.pkgs = inputs'.nixpkgs.legacyPackages;

          formatter = config.treefmt.build.wrapper;
        };
        # CI
        flake.hydraJobs =
          let
            inherit (nixpkgs) lib;
            buildHomeManager = arch:
              lib.mapAttrs' (name: config: lib.nameValuePair "home-manager-${name}-${arch}" config.activation-script) self.legacyPackages.${arch}.homeConfigurations;
          in
          (lib.mapAttrs' (name: config: lib.nameValuePair "nixos-${name}" config.config.system.build.toplevel) self.nixosConfigurations)
          // (buildHomeManager "x86_64-linux")
          // (buildHomeManager "aarch64-linux")
          // (buildHomeManager "aarch64-darwin")
          // {
            inherit (self.checks.x86_64-linux) treefmt;
          };
      }).config.flake;
}
