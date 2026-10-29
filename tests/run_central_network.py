"""Dedicated WebSocket authority plus three human clients, using real scenes."""
import pathlib
import socket
import subprocess
import sys
import time

root = pathlib.Path(__file__).resolve().parents[1]
binary = sys.argv[1] if len(sys.argv) > 1 else "godot"
with socket.socket() as sock:
    sock.bind(("127.0.0.1", 0))
    port = sock.getsockname()[1]
processes = []
try:
    for role in range(4):
        processes.append(subprocess.Popen(
            [binary, "--headless", "--path", str(root), "--script", "tests/central_network.gd", "--", str(role), str(port)],
            stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True))
        time.sleep(0.5)
    failed = False
    for process in processes:
        output, _ = process.communicate(timeout=65)
        print(output)
        failed |= process.returncode != 0 or "ERROR:" in output or "PASS" not in output
    raise SystemExit(1 if failed else 0)
finally:
    for process in processes:
        if process.poll() is None: process.kill()
        process.wait()
