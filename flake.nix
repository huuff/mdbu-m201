{
  description = "Following the exercises of MongoDB University M201 course";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs, ... }:
  let
    system = "x86_64-linux";
  in {
    nixosConfigurations.container = nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [
        ({ pkgs, ... }: 
        let
          port = 27017;
          databaseName = "m201";
          peopleCollection = "people";
          restaurantsCollection = "restaurants";
        in {
          boot.isContainer = true;

          nixpkgs.config.allowUnfree = true;

          environment.systemPackages = with pkgs; [
            mongodb-4_2 netcat
          ];

          services.mongodb = {
            enable = true;
            bind_ip = "0.0.0.0";
            extraConfig = ''
              net:
                port: ${toString port}
            '';

            initialScript = pkgs.writeText "create-collections" ''
              db.getSiblingDB("${databaseName}");
              db.createCollection("${peopleCollection}");
              db.createCollection("${restaurantsCollection}");
            '';
          };

          networking.useDHCP = false;
          networking.firewall.allowedTCPPorts = [ port 2222 ];

          systemd.services = {
            import-files = {
              description = "Import example files into DB";

              path = with pkgs; [ mongodb-tools ];

              wantedBy = ["multi-user.target"];
              bindsTo = [ "mongodb.service" ];

              script = ''
                mongoimport --db ${databaseName} --collection ${peopleCollection} --host localhost --port ${toString port} --drop --file ${./people.json}
                mongoimport --db ${databaseName} --collection ${restaurantsCollection} --host localhost --port ${toString port} --drop --file ${./restaurants.json}
              '';

              unitConfig = {
                Type = "oneshot";
              };
            };
          };
        })
      ];
    };
  };
}
