"""Fast filesystem/scene contract checks; no Godot binary or paid service required."""
from pathlib import Path
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
LOBBY = (ROOT / "Scripts/LobiPaneli.gd").read_text(encoding="utf-8")
BATTLE = (ROOT / "Scripts/SavasYonetici.gd").read_text(encoding="utf-8")
SCENE = (ROOT / "AnaOyun.tscn").read_text(encoding="utf-8")
MISSING = []

for name in ("osmanli", "misir", "venedik", "bizans", "mogol", "viking"):
    path = ROOT / "Assets" / "Flamalar" / f"{name}_flama.png"
    if not path.is_file():
        MISSING.append(str(path.relative_to(ROOT)))

if 'res://Assets/Flamalar/' not in LOBBY:
    MISSING.append("Lobby must load Assets/Flamalar")
if 'res://Assets/Bayraklar/' in LOBBY:
    MISSING.append("Lobby still references nonexistent Assets/Bayraklar")
if 'res://Assets/Resimler/zarlar/' in BATTLE:
    MISSING.append("Battle references nonexistent dice textures")
for node in ("AtakZarSonucu", "DefansZarSonucu"):
    if f'[node name="{node}"' not in SCENE:
        MISSING.append(f"Missing dice-result label: {node}")

# Pioneer Camp must use a distinct card illustration, not a civilization unit sprite.
CARD_UI = (ROOT / "Scripts/KartUI.gd").read_text(encoding="utf-8")
CAMP_ART = ROOT / "Assets/Resimler/kartresimleri/oncukampi.svg"
if not CAMP_ART.is_file():
    MISSING.append("Pioneer Camp card illustration is missing")
else:
    try:
        svg = ET.parse(CAMP_ART).getroot()
        if not svg.tag.endswith("svg"):
            MISSING.append("Pioneer Camp illustration is not SVG")
    except ET.ParseError:
        MISSING.append("Pioneer Camp illustration has invalid SVG XML")
if 'preload("res://Assets/Resimler/kartresimleri/oncukampi.svg")' not in CARD_UI:
    MISSING.append("Pioneer Camp art is not imported in the card UI")
if 'oncu_osmanli.png' in CARD_UI:
    MISSING.append("Card UI still falls back to Osmanli pioneer unit sprite")

if MISSING:
    raise SystemExit("Project asset/scene checks failed:\n- " + "\n- ".join(MISSING))
print("HUKUM project checks: PASS")
