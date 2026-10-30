"""Fast filesystem/scene contract checks; no Godot binary or paid service required."""
from pathlib import Path
import re
import struct

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
CAMP_ART = ROOT / "Assets/Resimler/kartresimleri/oncukampi.png"
if not CAMP_ART.is_file():
    MISSING.append("Pioneer Camp card illustration is missing")
else:
    header = CAMP_ART.read_bytes()[:24]
    if header[:8] != b"\x89PNG\r\n\x1a\n":
        MISSING.append("Pioneer Camp illustration must be PNG")
    else:
        width, height = struct.unpack(">II", header[16:24])
        if width < 246 or height < 393 or abs(width / height - 246 / 393) > .03:
            MISSING.append("Pioneer Camp illustration must match the portrait card proportions")
CARD_SCENE = (ROOT / "KartUI.tscn").read_text(encoding="utf-8")
if 'OncuKampiDetay' in CARD_SCENE or 'oncu_kampi_detay' in CARD_UI:
    MISSING.append("Pioneer Camp must not overlay drawings on another card")
if 'const ONCU_KAMPI_KARTI = preload("res://Assets/Resimler/kartresimleri/oncukampi.png")' not in CARD_UI:
    MISSING.append("Pioneer Camp must use its own complete card artwork")
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

for scene_path in ROOT.glob("*.tscn"):
    scene_text = scene_path.read_text(encoding="utf-8")
    declared = set(re.findall(r'\[ext_resource[^\n]+ id="([^"]+)"', scene_text))
    used = set(re.findall(r'ExtResource\("([^"]+)"\)', scene_text))
    for missing_id in sorted(used - declared):
        MISSING.append(f"{scene_path.name}: undefined external resource {missing_id}")

if MISSING:
    raise SystemExit("Project asset/scene checks failed:\n- " + "\n- ".join(MISSING))
print("HUKUM project checks: PASS")


