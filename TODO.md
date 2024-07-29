### TODO

- [ ] Check if we can change the tooltip font
- [x] Test if spell reflect works
- [ ] Look into coloring the tooltip according to EavesDrop setting and not based on Blizzard's settings
- [x] Use shortenValue in Histroy frame, make sure to use zero if crit or normal hit is missing
- [ ] Add new spell schools (such as Cosmic) to color options, and start tracking them in `EavesDropStats.lua`
- [ ] Revisit XML files to better fix/apply `BackdropTemplate`
- [ ] Check if we are using all combat events and nothing falls through cracks.
- [ ] Track SPELL_DISPELLED?
- [x] Track SPELL_HEAL_ABSORBED
- [ ] Use new ScrollableListTemplate?!!!
- [x] Add a pre-commit check to ensure all @debug@ and @end-debug@ are correctly spelled/used.
- [ ] Add a pre-commit check to ensure for every @debug@ we have a proper @end-debug@. Should be run after previous pre-commit check
- [ ] Add option to apply healing school color
- [x] Adjust values of small heal/damage filters based on current expansion
- [x] Calculate total heal/dmg correctly! Right now events that are filtered or have small values do not get counted!


### Misc

Use `.release/release.sh -d -u` to release locally and check for mistakes related to --@debug@ !