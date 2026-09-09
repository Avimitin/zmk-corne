{inputs, ...}: {
  perSystem = {
    system,
    pkgs,
    lib,
    ...
  }: let
    builders = inputs.zmk-nix.legacyPackages.${system};

    # Nix is the sole build-matrix definition. Each target becomes an
    # individual package and is also collected by corne-firmware below.
    targets = [
      {
        board = "nice_nano@2.0.0//zmk";
        shield = "corne_left";
        artifactName = "corne_left-nice_nano_v2-zmk";
      }
      {
        board = "nice_nano@2.0.0//zmk";
        shield = "corne_right";
        artifactName = "corne_right-nice_nano_v2-zmk";
      }
      {
        board = "nice_nano@2.0.0//zmk";
        shield = "settings_reset";
        artifactName = "settings_reset-nice_nano_v2-zmk";
      }
    ];

    # Only configuration affects firmware derivations. Documentation and Nix
    # implementation changes therefore do not invalidate compiled firmware.
    firmwareSource = lib.fileset.toSource {
      root = ../.;
      fileset = ../config;
    };

    # West dependencies are fetched once as a fixed-output derivation. The
    # manifest revision and this content hash jointly pin the entire workspace.
    westDeps = builders.fetchZephyrDeps {
      name = "corne-zmk-west-dependencies";
      src = firmwareSource;
      westRoot = "config";
      hash = "sha256-777sDty25V5VbWgXjYKpy1NEW/rWJEihU7DRdqfk30I=";
    };

    artifactName = target:
      target.artifactName
      or "${lib.optionalString (target ? shield) "${target.shield}-"}${builtins.replaceStrings ["/"] ["_"] target.board}-zmk";

    packageName = target: builtins.replaceStrings ["_" "@" "/"] ["-" "-" "-"] (artifactName target);

    buildTarget = target:
      builders.buildKeyboard {
        name = packageName target;
        src = firmwareSource;
        inherit westDeps;
        zephyrDepsHash = "";
        config = "config";
        inherit (target) board;
        shield = target.shield or null;

        meta = {
          description = "ZMK firmware for ${target.shield or target.board}";
          license = lib.licenses.mit;
          platforms = lib.platforms.all;
        };
      };

    targetBuilds =
      map (target: {
        inherit target;
        firmware = buildTarget target;
        artifact = artifactName target;
        package = packageName target;
      })
      targets;

    targetPackages = builtins.listToAttrs (map (build: {
        name = build.package;
        value = build.firmware;
      })
      targetBuilds);

    corneFirmware =
      pkgs.runCommand "corne-firmware" {
        inherit westDeps;
        passthru = {
          inherit targetBuilds;
        };
        meta = {
          description = "All locally defined Corne ZMK firmware artifacts";
          license = lib.licenses.mit;
          platforms = lib.platforms.all;
        };
      } (''
          mkdir -p "$out"
        ''
        + lib.concatMapStringsSep "\n" (build: ''
          install -Dm444 ${build.firmware}/zmk.uf2 "$out/${build.artifact}.uf2"
        '')
        targetBuilds);
  in {
    packages =
      targetPackages
      // {
        default = corneFirmware;
        corne-firmware = corneFirmware;
        # zmk-nix's updater defaults to this attribute name.
        firmware = corneFirmware;
        update = inputs.zmk-nix.packages.${system}.update;
      };

    devShells.default = inputs.zmk-nix.devShells.${system}.default;

    formatter = pkgs.alejandra;
  };
}
