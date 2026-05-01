# Development

Guidelines for working on this project.

## SFX

In game sounds:

00 - land sound (when pill touches the ground)
01 - move sound (when you move the pill left or right)
02 - rotate sound (when you rotate the pill clockwise or counterclockwise)
03 - clear sound (when you line up 4 colors in a row / column)
04 - overflow sound (when you don't have more space for a new pill)
05 - invalid move sound (you either rotate a pill or move a pill in such a way that validates the grid)
06 - drop move sound (when you press up and the binding drops to the ground)

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
40 - regular square wave instrument, created for title theme, may use in other tracks as well
41 - percussion 1

## Music

track 01 - fever
track 02 - title

## Waves

00 - 07: Generic waves, used across different sound effects and tracks
12 - 15: Instrument "per character" so that each character has its own "music vibe" (12 is character1, 13 character2, 14 character3, 15 character4)
(note: other than just instruments, characters use different base notes for their sound effects)
