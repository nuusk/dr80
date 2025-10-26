# Development

Guidelines for working on this project.

## SFX

In game sounds:

00 - drop sound (when pill touches the ground)
01 - move sound (when you move the pill left or right)
02 - rotate sound (when you rotate the pill clockwise or counterclockwise)
03 - clear sound (when you line up 4 colors in a row / column)
04 - overflow sound (when you don't have more space for a new pill)
05 - invalid move sound (you either rotate a pill or move a pill in such a way that validates the grid)

Menu sounds:

48 - menu select (moving cursor in the menu)
49 - menu confirm
50 - menu revert / go back (reverted confirm)

Instruments:

32 - regular square wave, volume 100%-0% in half duration
33 - trumpet, sounds nice with a vibrato, designed for track 00, pattern 03
34 - short triangle wave, used for stopping trumpet vibrato in track 00, pattern 03
35 - medium size triangle wave, used for bass
36 - triangle wave with offset (vol 0-100-0), main instrument

## Music
