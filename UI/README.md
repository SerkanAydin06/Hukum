# HÜKÜM UI skins

`HukumTheme.tres` is the shared theme for the menu, lobby, cards, HUD and dialogs.
The editable artwork lives in `Skins/*.svg`; it contains no text.

- `Button`: black enamel, engraved gold rim and four small fixed corner inlays.
- `HukumPrimary`: warmer gold emphasis for confirm, ready, start and end-turn actions.
- `HukumDanger`: dark red accent for attack, destroy, reject and exit actions.
- `HukumCompact`: smaller padding/lettering for card actions and narrow HUD controls.
- All roles include normal, hover, pressed/selected, hover while selected, disabled and keyboard focus states.

Buttons use `StyleBoxTexture` with **20px nine-patch borders**. Windows use the
same construction with **24px borders** and an opaque black center. Keep the
corners fixed; never stretch the complete texture or bake lettering into it.
Minimum artwork size is 40 × 40 for buttons and 48 × 48 for windows; visible
controls may need larger dimensions to fit their text. Let containers determine
text minimum sizes. Use a true `Button` for commands. Portraits, flags, terrain,
card faces and player-color swatches retain their aspect-preserving art selectors.

Use `theme_type_variation` to choose a role. New windows use `HukumWindow.gd`
(which inherits `PanelContainer`) and the shared theme. `HukumPanel` and
`HukumSlot` provide smaller panel padding; `HukumPortrait` is an unframed inset.
Do not layer an independent rectangular fill over the shaped window texture.

`skin-audit.csv` lists every authored command, selector and panel. Verify with:

```sh
python tests/check_project.py
godot --headless --path . --script tests/ui_scaling.gd
# With a graphical display, this also compares the actual rendered corners:
godot --path . --rendering-method gl_compatibility --script tests/ui_scaling.gd
# Render every authored panel individually for visual review:
godot --path . --rendering-method gl_compatibility --script tests/ui_catalog.gd
```

Visual test PNGs are written to `/tmp/hukum-ui-*.png`; they are not shipped assets.
