"""Run gameplay regressions in an isolated Godot project without requiring art assets.
Usage: python tests/run_regressions.py /path/to/godot
"""
import pathlib
import re
import shutil
import subprocess
import sys
import socket
import time
import tempfile

ROOT = pathlib.Path(__file__).resolve().parents[1]
SCRIPTS = sorted((ROOT / "Scripts").glob("*.gd"))
with tempfile.TemporaryDirectory(prefix="hukum-tests-") as directory:
    target = pathlib.Path(directory)
    (target / "Scripts").mkdir()
    (target / "project.godot").write_text('''config_version=5
[application]
config/name="Hukum regression tests"
run/main_scene="res://runner.tscn"
[autoload]
Global="*res://Scripts/Global.gd"
PardexBridge="*res://Scripts/PardexBridge.gd"
Network="*res://Scripts/Network.gd"
PardexLink="*res://Scripts/PardexLink.gd"
SceneTransition="*res://Scripts/SahneGecisleri.gd"
SesYoneticisi="*res://Scripts/SesYoneticisi.gd"
[rendering]
renderer/rendering_method="gl_compatibility"
''')
    (target / "KartUI.tscn").write_text('[gd_scene format=3]\n[node name="KartUI" type="Control"]\n')
    (target / "runner.tscn").write_text('[gd_scene load_steps=2 format=3]\n[ext_resource type="Script" path="res://regressions.gd" id="1"]\n[node name="Regressions" type="Node"]\nscript = ExtResource("1")\n')
    # Verify the real card background and overlay assets in the isolated Godot test.
    art_paths = [
        pathlib.Path("Assets/Resimler/kartresimleri/oncukampi_cadir.svg"),
        pathlib.Path("Assets/Resimler/kartresimleri/oduncu.png"),
        *[p.relative_to(ROOT) for p in (ROOT / "Assets/Audio/UI").glob("*.wav")],
    ]
    for asset in art_paths:
        (target / asset.parent).mkdir(parents=True, exist_ok=True)
        shutil.copy(ROOT / asset, target / asset)
    (target / "UI").mkdir()
    shutil.copy(ROOT / "UI/HukumWindow.gd", target / "UI/HukumWindow.gd")
    for source in SCRIPTS:
        def replace_asset_preload(match):
            return match.group(0) if "res://UI/HukumWindow.gd" in match.group(0) or "res://Assets/Resimler/kartresimleri/oduncu.png" in match.group(0) or "res://Assets/Resimler/kartresimleri/oncukampi_cadir.svg" in match.group(0) else "null"

        text = re.sub(r'preload\(\s*"res://(?:Assets|UI)/[^"\n]+"\s*\)',
                      replace_asset_preload, source.read_text())
        (target / "Scripts" / source.name).write_text(text)
    shutil.copy(ROOT / "tests" / "regressions.gd", target)
    binary = sys.argv[1] if len(sys.argv) > 1 else "godot"
    for arguments in (["--editor", "--import", "--quit"], []):
        result = subprocess.run([binary, "--headless", "--path", str(target), *arguments],
                                capture_output=True, text=True, timeout=60)
        output = result.stdout + result.stderr
        print(output)
        if result.returncode or "SCRIPT ERROR" in output or "Parse Error" in output or "ERROR:" in output:
            raise SystemExit(result.returncode or 1)

    # Exercise actual ENet sender IDs, RPC replication and atomic card consumption.
    shutil.copy(ROOT / "tests" / "network_smoke.gd", target)
    (target / "runner.tscn").write_text('[gd_scene load_steps=2 format=3]\n[ext_resource type="Script" path="res://network_smoke.gd" id="1"]\n[node name="Regressions" type="Node"]\nscript = ExtResource("1")\n')
    with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as sock:
        sock.bind(("127.0.0.1", 0))
        port = str(sock.getsockname()[1])
    commands = [binary, "--headless", "--path", str(target), "--"]
    server = subprocess.Popen([*commands, "server", port], stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
    try:
        time.sleep(0.3)
        client = subprocess.Popen([*commands, "client", port], stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
        try:
            client_log, _ = client.communicate(timeout=25)
            server_log, _ = server.communicate(timeout=25)
        finally:
            if client.poll() is None: client.kill()
        print(server_log + client_log)
        if server.returncode or client.returncode or "ERROR:" in server_log + client_log or "HUKUM ENET SMOKE: PASS" not in server_log:
            raise SystemExit(1)
    finally:
        if server.poll() is None: server.kill()

