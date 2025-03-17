{
  description = "A flake for developing and running goat-cache";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };
  outputs = inputs @ {flake-parts, ...}:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];
      perSystem = {
        self',
        pkgs,
        ...
      }: let
        commonArgs = rec {
            version = "v0.1";
            name = "goat-cache";
            pname = "goat-cache";
            src = ./.;
            vendorHash = "sha256-HmPLD3c8LLRm9K383nVVGQ2x/xAZvFO8aITeYyCmvuE=";
            ldflags = ["-X main.Version=${version}"];
            subPacakges = ["cmd/goat-cache"];
            env = {
                CGO_ENABLED = "0";
            };
            doCheck = false;
        };
        package = pkgs.buildGoModule(commonArgs // {});
        dockerArgs = {
            inherit (commonArgs) name;
            tag = (commonArgs.version);
            config = {
            };
            

            copyToRoot = [
                pkgs.dockerTools.caCertificates
                pkgs.dockerTools.binSh
            ];
        };
        in{
        packages = {
            default = package; 
            docker = pkgs.dockerTools.buildImage dockerArgs // {
                config = {
                 Cmd = ["${self'.packages.default}/bin/goat-cache"];
                 # Env = [
                 #    "SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt"
                 # ];
                };
            };
                       
        };
        checks.default = package;
        devShells = {
          default = pkgs.mkShell {
            inputsFrom = [self'.packages.default];
            packages = with pkgs; [sqlc go];
          };
        };
        formatter = pkgs.alejandra;
      };
    };
}

