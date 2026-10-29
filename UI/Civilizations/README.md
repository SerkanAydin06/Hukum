# Civilization crests

Six new transparent PNG insignia generated with the built-in imagegen tool.
The existing civilization flags supplied the visual reference. These are game
ornaments inspired by their civilizations, rather than historical reproductions.

| File | Theme |
| --- | --- |
| osmanli_crest.png | Burgundy, crescent/star, tulip and tezhip |
| venedik_crest.png | Sapphire blue, winged lion, ropes and waves |
| bizans_crest.png | Imperial purple, cross, acanthus and meander |
| misir_crest.png | Turquoise/lapis, Horus eye, scarab and lotus |
| mogol_crest.png | Umber/amber, wolf, crossed bows and braid |
| viking_crest.png | Cold teal, dragon longship and interlaced knotwork |

`prompts.json` records the complete prompt for each final asset and reference
paths. Original transparent alpha and resolution are retained. Each image is a
loadable resource dependency; it is reused at different sizes with aspect ratio
preserved. The procedural panel watermark reduces opacity at draw time and
never changes the image itself. No words are baked into the crests.
