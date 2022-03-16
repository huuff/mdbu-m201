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
        ({ pkgs, config, ... }: 
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
            package = pkgs.mongodb-4_2;
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

              path = with pkgs; [ mongodb-tools gzip ];

              wantedBy = ["multi-user.target"];
              bindsTo = [ "mongodb.service" ];

              script = ''
                mongoimport --db ${databaseName} --collection ${peopleCollection} --host localhost --port ${toString port} --drop --file ${./people.json}

                tmp_dir=$(mktemp -d)
                cp ${./restaurants.json.gz} $tmp_dir
                gunzip $tmp_dir/*.gz
                mongoimport --db ${databaseName} --collection ${restaurantsCollection} --host localhost --port ${toString port} --drop --file $tmp_dir/*.json
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
