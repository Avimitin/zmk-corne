# Bluetooth pairing and troubleshooting

The Corne uses its left half as the central controller. Only the left half
advertises to computers; the right half connects to the left half as a split
peripheral. The configured Bluetooth name is `Corne(nano)`.

## Select a Bluetooth profile

The keyboard has five persistent host profiles. Hold the middle thumb key on
each half at the same time (`MO 1` on the left and `MO 2` on the right) to
activate the system layer, then press one of these keys:

| Key | Profile |
| --- | ------- |
| Q   | 1       |
| W   | 2       |
| E   | 3       |
| R   | 4       |
| T   | 5       |

Selecting an unused profile makes the keyboard advertise automatically. To
reuse a profile, select it first, then activate the system layer again and
press X. This clears only the selected host bond.

## Pair from Linux

Start `bluetoothctl`, enable its pairing agent, and scan for the keyboard:

```text
[bluetoothctl]> power on
[bluetoothctl]> agent on
[bluetoothctl]> default-agent
[bluetoothctl]> scan le
```

After `Corne(nano)` appears, note its current address and stop scanning. Always
use the address reported by the current scan rather than copying one from an
older log.

The normal pairing sequence is:

```text
[bluetoothctl]> scan off
[bluetoothctl]> pair AA:BB:CC:DD:EE:FF
[bluetoothctl]> trust AA:BB:CC:DD:EE:FF
```

Replace `AA:BB:CC:DD:EE:FF` with the address shown for `Corne(nano)`.

## `AuthenticationRejected` on BlueZ

On the tested Linux host, pairing failed repeatedly with:

```text
Failed to pair: org.bluez.Error.AuthenticationRejected
```

The confirmed host configuration was BlueZ 5.87 on Linux 6.18.44 with a
Realtek `0bda:4853` controller. A `btmon` capture showed that the kernel
management `Pair Device` request returned `Busy (0x0a)` before an LE connection
or SMP authentication exchange reached the keyboard. The error was therefore
host-side and was not caused by a stale ZMK bond.

The working sequence is to establish the LE connection before pairing:

```text
[bluetoothctl]> scan off
[bluetoothctl]> connect AA:BB:CC:DD:EE:FF
[bluetoothctl]> pair AA:BB:CC:DD:EE:FF
[bluetoothctl]> trust AA:BB:CC:DD:EE:FF
[bluetoothctl]> info AA:BB:CC:DD:EE:FF
```

A successful result contains:

```text
Paired: yes
Bonded: yes
Trusted: yes
Connected: yes
```

If BlueZ no longer knows the device address, run `scan le` again before
`connect`. If an old host-side bond exists, remove it, rescan, and repeat the
connect-before-pair sequence:

```text
[bluetoothctl]> remove AA:BB:CC:DD:EE:FF
```

## Erase all keyboard settings

Use this only when clearing one Bluetooth profile is insufficient. It erases
all host profiles, output selection, lighting state, and the bond between the
two keyboard halves.

First build the firmware:

```sh
nix build '.#corne-firmware'
```

Then perform these steps in order:

1. Turn off both halves.
2. Put the left half into its bootloader and flash
   `result/settings_reset-nice_nano_v2-zmk.uf2`.
3. Put the right half into its bootloader and flash the same settings-reset
   image.
4. Only after both resets are complete, flash
   `result/corne_left-nice_nano_v2-zmk.uf2` to the left half.
5. Flash `result/corne_right-nice_nano_v2-zmk.uf2` to the right half.
6. Power-cycle both halves at approximately the same time.
7. Remove or forget `Corne(nano)` on the host, then pair it again.

The settings-reset image intentionally disables Bluetooth. The keyboard will
not advertise while that image is installed; normal left and right firmware
must be restored afterward.

## References

- [ZMK Bluetooth behavior](https://zmk.dev/docs/keymaps/behaviors/bluetooth)
- [ZMK split-keyboard reset procedure](https://zmk.dev/docs/troubleshooting/connection-issues#reset-split-keyboard-procedure)
- [BlueZ management protocol](https://github.com/bluez/bluez/blob/master/doc/mgmt-protocol.rst)
