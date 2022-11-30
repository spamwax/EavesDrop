### TODO

- [ ] Check if we can change the tooltip font
- [ ] Test if spell reflect works
- [ ] Look into coloring the tooltip according to EavesDrop setting and not based on Blizzard's settings
- [ ] Use shortenValue in Histroy frame, make sure to use zero if crit or normal hit is missing
- [ ] Add new spell schools (such as Cosmic) to color options, and start tracking them in `EavesDropStats.lua`
- [ ] Revisit XML files to better fix/apply `BackdropTemplate`
- [ ] Check if we are using all combat events and nothing falls through cracks.
- [ ] Use new ScrollableListTemplate?!!!
- [x] Add a pre-commit check to ensure all @debug@ and @end-debug@ are correctly spelled/used.
- [ ] Add a pre-commit check to ensure for every @debug@ we have a proper @end-debug@. Should be run after previous pre-commit check