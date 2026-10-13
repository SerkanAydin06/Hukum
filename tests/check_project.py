"""Fast filesystem/scene contract checks; no Godot binary or paid service required."""
from pathlib import Path

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

if MISSING:
    raise SystemExit("Project asset/scene checks failed:\n- " + "\n- ".join(MISSING))
print("HUKUM project checks: PASS")
