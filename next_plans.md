# Next Plans

## Biggest Gaps

- Proper end-of-match flow
  - A board can lose, but there is no winner screen, round-end flow, rematch, or return-to-menu sequence.
  - Evidence: `dr80.lua:751-754`, `dr80.lua:1388-1433`, `dr80.lua:1736-1744`

- Real single-player mode
  - The menu only exposes VS, and only for `2/3/4` players.
  - There is code for `1` player board sizing, but no menu path to it.
  - Evidence: `dr80.lua:215-217`, `dr80.lua:1665-1704`, `dr80.lua:1365-1374`

- Finished pre-match setup
  - There is a params scene, but it does not seem reachable from the menu.
  - It also calls `param_up()` / `param_down()` hooks that are not implemented.
  - Evidence: `dr80.lua:209-213`, `dr80.lua:1259-1267`, `dr80.lua:1771-1789`, `dr80.lua:1816-1825`

- Meaningful difficulty/level setup
  - `level` exists, but game setup still hardcodes `generate_stones(5)`, so level selection is not really driving the match yet.
  - Evidence: `dr80.lua:376`, `dr80.lua:399-401`

- Character select/customization
  - Characters are auto-assigned from player index rather than chosen by the player.
  - Evidence: `dr80.lua:399-401`, `dr80.lua:472-487`

- Real pause behavior
  - Pause input is wired to debug logging, not pausing.
  - `is_paused` exists but is never actually turned on.
  - Evidence: `dr80.lua:385`, `dr80.lua:1379-1385`, `dr80.lua:1722-1724`, `dr80.lua:1741-1744`

- Better menu/UI shell
  - The menu structure is very minimal right now: basically `VS GAME` then player count.
  - No obvious tutorial/help/options/results flow.
  - Evidence: `dr80.lua:1665-1704`

- More complete feedback polish
  - Some SFX are documented but not fully used in gameplay.
  - Land SFX is still commented out.
  - Evidence: `DEVELOPMENT.md:9-21`, `dr80.lua:1048-1083`

## Highest Impact Next

1. End-of-match + winner/rematch flow
2. Exposed 1-player mode
3. Working params screen with real level/difficulty setup
