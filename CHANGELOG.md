# Changelog

## Unreleased
- Centralized sensitivity state flow (normalize → save → sync UI → apply CVars) for consistent behavior across slider, edit box, buttons, and slash commands
- Settings panel status line shows applied/saved-while-locked state; fewer chat messages from UI/load actions
- Addon compartment tooltip shows current sensitivity
- Internal refactor to make load/apply/UI-sync states explicit

## 0.1.0
- Initial release
- Slider 0.1–100 with 0.01 precision
- Manual numeric entry, Reset, Apply
- `/sens` and `/sensitivity` commands
- Settings panel in AddOns tab
- Addon compartment button
- SavedVariables persistence
