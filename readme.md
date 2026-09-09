# Corne ZMK firmware

This repository can build the complete firmware set locally with Nix. The
flake pins the Nix toolchain, ZMK, Zephyr, and every West dependency, so no
system-wide Zephyr SDK or `west` installation is needed.

## Local build

With [Nix](https://nixos.org/download/) and flakes enabled, run:

```sh
nix build '.#corne-firmware'
```

The `result` directory contains all three firmware artifacts:

```text
corne_left-nice_nano_v2-zmk.uf2
corne_right-nice_nano_v2-zmk.uf2
settings_reset-nice_nano_v2-zmk.uf2
```

The first build downloads and stores the pinned toolchain and West workspace.
Later builds reuse those dependencies. Editing `config/corne.keymap` or
`config/corne.conf` only rebuilds the firmware derivations.

To build one target while iterating, use one of:

```sh
nix build '.#corne-left-nice-nano-v2-zmk'
nix build '.#corne-right-nice-nano-v2-zmk'
nix build '.#settings-reset-nice-nano-v2-zmk'
```

The target list in `nix/firmware.nix` is the sole build definition. Add or
remove firmware variants there. A development shell containing the ZMK build
tools is also available with `nix develop`.

## Updating dependencies

ZMK is pinned to the `main` commit recorded in `config/west.yml`. To advance
that commit and refresh the fixed hash for its complete West workspace, run:

```sh
nix run '.#update'
```

To update the Nix-side inputs (`nixpkgs`, `flake-parts`, and `zmk-nix`), run:

```sh
nix flake update
```

Review and commit `config/west.yml`, `nix/firmware.nix`, and `flake.lock`
together after verifying a full build.

## Flashing

1. Edit the keymap with the [ZMK Keymap Editor](https://nickcoutsos.github.io/keymap-editor/).
2. Run `nix build '.#corne-firmware'`.
3. Reset a keyboard half into its bootloader.
4. Copy the corresponding left or right UF2 file from `result/` to it.
5. Repeat for the other half, then reboot both halves.

The settings-reset image is only needed when clearing stored bonds and
settings; flash it temporarily, then flash the normal firmware again.

## Bluetooth

See [Bluetooth pairing and troubleshooting](docs/bluetooth.md) for the
configured profile keys, the full storage-reset procedure, and the confirmed
Linux workaround for BlueZ reporting `AuthenticationRejected`.
