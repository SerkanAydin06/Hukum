# HÜKÜM UI skins

`HukumTheme.tres` is the shared theme for the menu, lobby, cards, HUD and dialogs.
The editable artwork lives in `Skins/*.svg`; it contains no text.

- `Button`: raised black enamel, a bright upper bevel, deep lower lip and fixed gold corner inlays.
- `HukumPrimary`: warmer gold emphasis for confirm, ready, start and end-turn actions.
- `HukumDanger`: dark red accent for attack, destroy, reject and exit actions.
- `HukumCompact`: smaller padding/lettering for card actions and narrow HUD controls.
- All roles include normal, hover, pressed/selected, hover while selected, disabled and keyboard focus states. Pressed faces and lettering sink into the frame.

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

## Civilization presentation

`CivilizationStyle.gd` applies the local player's selected civilization to the
HUD, dialogs, card command buttons and lobby preview. It changes no match data.
The six gold crests in `Civilizations/` appear on end-turn buttons and as one
centered watermark per panel/card area. Combat and construction deck tabs use
fixed crossed-swords and hammer/anvil icons in every civilization. The palettes retain black centers and gold bevels:
Ottoman burgundy/tulips, Venetian blue/waves, Byzantine purple/meanders,
Egyptian turquoise/lotus, Mongol amber/braid and Viking teal/knotwork.
Destructive buttons retain their red warning palette.

Skins are cached per civilization; the same decoration nodes are reused.
Newly dealt card scenes inherit the current skin. `PortraitBorder.gd` uses the
existing gold avatar-frame artwork and hover frame; the picker keeps its bright
selected-frame state. The upper-right HUD button has no surrounding panel background and opens the menu; settings stay
inside that menu.

After editing `Skins/standard_*.svg`, `Skins/primary_*.svg` or `Skins/window.svg`,
run `python UI/build_civilization_templates.py`. Embedded SVG templates ensure
palette generation works in exported games where imported source SVGs may not
be directly readable. Crest resources are explicit dependencies for exports.

Portrait images use `PortraitMask.gdshader` through `PortraitBorder.gd`.
The image is drawn only within the frame's inner lip; frame/hover/selection
art remains separate. Both the image aperture and square frame stay centered
when the parent is rectangular or resized. Rectangular source art is cropped
to cover the aperture without distortion. Battle portrait textures ignore
their natural image size when calculating the surrounding window's minimum.
