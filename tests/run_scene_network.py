"""Three real Godot scenes: lobby, setup, battle reveal/dice, spectator, disconnect."""
import pathlib
import subprocess
import sys
import time

root = pathlib.Path(__file__).resolve().parents[1]
binary = sys.argv[1] if len(sys.argv) > 1 else "godot"
processes = []
try:
    for role in range(3):
        processes.append(subprocess.Popen(
            [binary, *([] if "--render-spectator" in sys.argv and role == 2 else ["--headless"]), "--audio-driver", "Dummy", "--rendering-method", "gl_compatibility", "--path", str(root), "--script", "tests/scene_network.gd", "--", str(role)],
            stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True))
        time.sleep(0.35)
    failed = False
    for process in processes:
        output, _ = process.communicate(timeout=95)
        print(output)
        failed |= process.returncode != 0 or "ERROR:" in output or "PASS" not in output
    raise SystemExit(1 if failed else 0)
finally:
    for process in processes:
        if process.poll() is None:
            process.kill()
        process.wait()
