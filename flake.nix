{
  description = "A basic gomod2nix flake";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.gomod2nix.url = "github:nix-community/gomod2nix";
  inputs.gomod2nix.inputs.nixpkgs.follows = "nixpkgs";
  inputs.gomod2nix.inputs.flake-utils.follows = "flake-utils";

  outputs = inputs@{ self, nixpkgs, flake-utils, gomod2nix }:
    (flake-utils.lib.eachDefaultSystem
      (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};

          # The current default sdk for macOS fails to compile go projects, so we use a newer one for now.
          # This has no effect on other platforms.
          callPackage = pkgs.darwin.apple_sdk_11_0.callPackage or pkgs.callPackage;

          app = callPackage ./. {
            inherit (gomod2nix.legacyPackages.${system}) buildGoApplication;
          };
        in
        {
          packages.default = app;
          devShells.default = callPackage ./shell.nix {
            inherit (gomod2nix.legacyPackages.${system}) mkGoEnv gomod2nix;
          };

          nixosConfigurations.flakery = nixpkgs.lib.nixosSystem {
            system = system;
            modules = [
              { config, lib, pkgs, ... }:
              let
                flakeryDomain = builtins.readFile /metadata/flakery-domain;
              in
              {
                networking.firewall.allowedTCPPorts = [ 80 443 ];

                systemd.services.go-webserver = {
                  description = "go webserver";
                  after = [ "network.target" ];
                  wantedBy = [ "multi-user.target" ];
                  serviceConfig = {
                    ExecStart = "${app}/bin/app";
                    Restart = "always";
                    KillMode = "process";
                  };
                };

                services.caddy = {
                  enable = true;
                  virtualHosts."${flakeryDomain}".extraConfig = ''
                    handle /* {
                      reverse_proxy http://127.0.0.1:8080
                    }
                  '';
                };
              }

            ];
          };

        })
    );
}
