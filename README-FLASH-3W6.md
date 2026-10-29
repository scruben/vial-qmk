# Flashing the 3W6 (keycapsss/3w6_2040)

Built on branch `3w6-scruben`. This is the split 36-key keyboard with RP2040
halves and a Pimoroni trackball.

## Build

    ./build_3w6.sh

Output:

    dist/3w6_2040_vial_<branch>_<date>.uf2

(The same .uf2 goes on BOTH halves — master/slave is decided at runtime via
`MASTER_RIGHT` + `SPLIT_USB_DETECT` on VBUS pin GP19.)

## Flashing both halves

Flash one half at a time — never two BOOTDRIVEs at once.

Per half, repeat twice:

1. Unplug the keyboard.
2. Press and HOLD the BOOTSEL button on that half's RP2040 board.
3. While holding BOOTSEL, plug that half into USB
   (each half flashes through its own USB-C; the split link is not involved).
4. A USB drive named BOOTDRIVE / RP2040 appears.
5. Copy the .uf2 from `dist/` onto it.
   The drive disappears after ~2 seconds = flash succeeded, half reboots.
6. Repeat for the other half.

Then unplug both, and reconnect normally: one half to the computer,
TRRS between halves. The right half is the master.

## Troubleshooting

- Halves behave swapped/mirrored after flashing: that is hand detection,
  not the flash — check the split/USB-detect logic.
- Verify keymap/LED sync in the Vial app (https://usevial.org).
  Keyboard definition: `keyboards/keycapsss/3w6_2040/keymaps/vial/vial.json`.
- In a VM: the BOOTDRIVE may appear on the host OS instead of the guest —
  attach the USB device to the VM, or copy the .uf2 from the host
  (it is on the shared folder either way).
