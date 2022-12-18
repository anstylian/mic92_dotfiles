{self, ...}: let
  inherit
    (self.inputs)
    nixpkgs
    retiolum
    sops-nix
    home-manager
    nur
    flake-registry
    nixos-hardware
    bme680-mqtt
    hyprland
    ;

  inherit (nixpkgs) lib;

  nixosSystem = args:
    (lib.makeOverridable lib.nixosSystem)
    (lib.recursiveUpdate args {
      modules =
        args.modules
        ++ [
          {
            config.nixpkgs.pkgs = lib.mkDefault args.pkgs;
            config.nixpkgs.localSystem = lib.mkDefault args.pkgs.stdenv.hostPlatform;
          }
        ];
    });

  defaultModules = [
    # make flake inputs accessiable in NixOS
    {
      _module.args.self = self;
      _module.args.inputs = self.inputs;
    }
    ({pkgs, ...}: {
      nix.nixPath = [
        "nixpkgs=${pkgs.path}"
        "home-manager=${home-manager}"
        "nur=${nur}"
      ];

      #nix.extraOptions = let
      #  registry = pkgs.runCommand "flake-registry.json" {} ''
      #    jq 'setpath(;)' < ${flake-registry}/flake-registry.json > $out
      #  '';
      #in ''
      #  flake-registry = ${registry}/flake-registry.json
      #'';
      nix.extraOptions = ''
        flake-registry = ${flake-registry}/flake-registry.json
      '';
      documentation.info.enable = false;

      imports = [
        ./modules/upgrade-diff.nix
        ./modules/nix-daemon.nix
        ./modules/minimal-docs.nix
        ./modules/i18n.nix
        ./modules/nsncd.nix
        ./modules/sshd
        ./modules/self.nix
        nur.nixosModules.nur

        ./modules/retiolum.nix
        ./modules/update-prefetch.nix
        retiolum.nixosModules.retiolum
        retiolum.nixosModules.ca

        sops-nix.nixosModules.sops
      ];
    })
  ];
in {
  flake.nixosConfigurations = {
    bernie = nixosSystem {
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      modules =
        defaultModules
        ++ [
          nixos-hardware.nixosModules.lenovo-thinkpad-x13
          home-manager.nixosModules.home-manager
          ./bernie/configuration.nix
        ];
    };

    turingmachine = nixosSystem {
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      modules =
        defaultModules
        ++ [
          ./turingmachine/configuration.nix
          nixos-hardware.nixosModules.framework
          self.inputs.envfs.nixosModules.envfs
          hyprland.nixosModules.default

          #self.inputs.lanzaboote.nixosModules.lanzaboote
          #({pkgs, ...}: {
          #  programs.hyprland.enable = true;
          #  environment.systemPackages = [
          #    hyprland.packages.${pkgs.system}.waybar-hyprland
          #  ];
          #})
          # For testing systemd
          #({pkgs, ...}: {
          #  #systemd.package = self.inputs.nixpkgs-systemd.legacyPackages.${pkgs.system}.systemd;
          #  systemd.package = pkgs.systemd.overrideAttrs (old: {
          #    src = self.inputs.systemd;
          #  });
          #})
        ];
    };

    eve = nixosSystem {
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      modules =
        defaultModules
        ++ [
          ./eve/configuration.nix
          self.inputs.envfs.nixosModules.envfs
          "${self.inputs.harmonia}/module.nix"
          ({config, ...}: {
            services.harmonia.enable = true;
            services.harmonia.settings.sign_key_path = config.sops.secrets.harmonia-key.path;
            sops.secrets.harmonia-key.owner = "harmonia";

            nix.settings.allowed-users = ["harmonia"];

            services.nginx.virtualHosts."cache.thalheim.io" = {
              useACMEHost = "thalheim.io";
              forceSSL = true;
              locations."/".extraConfig = ''
                proxy_pass http://127.0.0.1:5000;
                proxy_set_header Host $host;
                proxy_redirect http:// https://;
                proxy_http_version 1.1;
                proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                proxy_set_header Upgrade $http_upgrade;
                proxy_set_header Connection $connection_upgrade;
              '';
            };
          })
        ];
    };

    rock = nixosSystem {
      pkgs = nixpkgs.legacyPackages.aarch64-linux;
      modules =
        defaultModules
        ++ [
          bme680-mqtt.nixosModules.bme680-mqtt
          ./rock/configuration.nix
        ];
    };

    blob64 = nixosSystem {
      pkgs = nixpkgs.legacyPackages.aarch64-linux;
      modules =
        defaultModules
        ++ [
          ./blob64/configuration.nix
        ];
    };

    matchbox = nixosSystem {
      pkgs = nixpkgs.legacyPackages.aarch64-linux;
      modules = defaultModules ++ [./matchbox/configuration.nix];
    };

    eva = nixosSystem {
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      modules =
        defaultModules
        ++ [
          ./eva/configuration.nix
        ];
    };
  };
}
