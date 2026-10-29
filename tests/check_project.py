"""Fast filesystem/scene contract checks; no Godot binary or paid service required."""
from pathlib import Path
import re
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
CAMP_ART = ROOT / "Assets/Resimler/kartresimleri/oncukampi_cadir.svg"
if not CAMP_ART.is_file():
    MISSING.append("Pioneer Camp card illustration is missing")
else:
    try:
        svg = ET.parse(CAMP_ART).getroot()
        if not svg.tag.endswith("svg"):
            MISSING.append("Pioneer Camp illustration is not SVG")
    except ET.ParseError:
        MISSING.append("Pioneer Camp illustration has invalid SVG XML")
CARD_SCENE = (ROOT / "KartUI.tscn").read_text(encoding="utf-8")
if 'OncuKampiDetay' not in CARD_SCENE or 'oncukampi_cadir.svg' not in CARD_SCENE:
    MISSING.append("Pioneer Camp card art overlay is missing in KartUI.tscn")
if 'ONCU_KAMPI_KART_ZEMINI' not in CARD_UI or 'oncu_kampi_detay.visible' not in CARD_UI:
    MISSING.append("Pioneer Camp must retain construction card frame and show tent overlay")
if '"Enrico Dandolo": "dandolo"' not in CARD_UI:
    MISSING.append("Enrico Dandolo commander image name must match dandolo.png")
PANEL = (ROOT / "Scripts/ArayuzYonetici.gd").read_text(encoding="utf-8")
if "binalar/oduncu%d.png" not in PANEL or "binalar/tasocagi%d.png" not in PANEL or "binalar/tarla%d.png" not in PANEL:
    MISSING.append("Building detail panel must use level-suffixed image names")
if 'oncu_osmanli.png' in CARD_UI:
    MISSING.append("Card UI still falls back to Osmanli pioneer unit sprite")

# Check every literal resource reference, including art/shaders/audio in scenes.
for source in list(ROOT.glob("*.tscn")) + list((ROOT / "Scripts").glob("*.gd")) + list((ROOT / "UI").glob("*.tres")) + list((ROOT / "UI").glob("*.gd")):
    for reference in re.findall(r'"res://([^"\n]+)"', source.read_text(encoding="utf-8")):
        if "%" in reference or reference.endswith("/"):
            continue  # dynamically assembled references are covered by runtime tests
        if not (ROOT / reference).exists():
            MISSING.append(f"{source.relative_to(ROOT)}: {reference}")

if MISSING:
    raise SystemExit("Project asset/scene checks failed:\n- " + "\n- ".join(MISSING))
print("HUKUM project checks: PASS")

