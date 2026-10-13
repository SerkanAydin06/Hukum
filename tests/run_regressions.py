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
Network="*res://Scripts/Network.gd"
Global="*res://Scripts/Global.gd"
SceneTransition="*res://Scripts/SahneGecisleri.gd"
SesYoneticisi="*res://Scripts/SesYoneticisi.gd"
[rendering]
renderer/rendering_method="gl_compatibility"
''')
    (target / "KartUI.tscn").write_text('[gd_scene format=3]\n[node name="KartUI" type="Control"]\n')
    (target / "runner.tscn").write_text('[gd_scene load_steps=2 format=3]\n[ext_resource type="Script" path="res://regressions.gd" id="1"]\n[node name="Regressions" type="Node"]\nscript = ExtResource("1")\n')
    # Keep the one real SVG under test; other art is intentionally excluded.
    camp_art = pathlib.Path("Assets/Resimler/kartresimleri/oncukampi.svg")
    (target / camp_art.parent).mkdir(parents=True)
    shutil.copy(ROOT / camp_art, target / camp_art)
    for source in SCRIPTS:
        def replace_asset_preload(match):
            return match.group(0) if "res://Assets/Resimler/kartresimleri/oncukampi.svg" in match.group(0) else "null"

        text = re.sub(r'preload\(\s*"res://Assets/[^"\n]+"\s*\)',
                      replace_asset_preload, source.read_text())
        (target / "Scripts" / source.name).write_text(text)
    shutil.copy(ROOT / "tests" / "regressions.gd", target)
    binary = sys.argv[1] if len(sys.argv) > 1 else "godot"
    for arguments in (["--editor", "--import", "--quit"], []):
        result = subprocess.run([binary, "--headless", "--path", str(target), *arguments],
                                capture_output=True, text=True, timeout=60)
        output = result.stdout + result.stderr
        print(output)
        if result.returncode or "SCRIPT ERROR" in output or "Parse Error" in output:
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
        if server.returncode or client.returncode or "SCRIPT ERROR" in server_log + client_log or "HUKUM ENET SMOKE: PASS" not in server_log:
            raise SystemExit(1)
    finally:
        if server.poll() is None: server.kill()
