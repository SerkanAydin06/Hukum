# HUKUM — AI working contract (ChatGPT / Codex / Claude Code)

> Source of truth: this file. Read at the start of any repository task; do not duplicate its full content in other agent files.
> Priority: user instructions and platform safety rules override this document.

## Project map
- Godot 4.7 (GDScript), turn-based multiplayer hex strategy; ENet UDP port 7777, max 6 players.
- Entry: `project.godot` → `AnaMenu.tscn`; network singleton: `Scripts/Network.gd`.
- Lobby: `Scripts/LobiPaneli.gd`; match state: `Scripts/AnaOyun.gd`.
- Gameplay: `Scripts/AksiyonYonetici.gd`, `AksiyonInsa.gd`, `AksiyonSavasTetik.gd`, `SavasYonetici.gd`, `TurEkonomiYonetici.gd`.
- Board/fog: `Scripts/Harita.gd`; cards: `Scripts/DesteYonetici.gd`; UI: `Scripts/ArayuzYonetici.gd`.
- Tests: `tests/run_regressions.py` (isolated Godot project, including two-process ENet smoke) and `tests/check_project.py`.
- Visual sources: `Assets/Flamalar/<civilization>_flama.png`, `Assets/Resimler/...`.

## Token / cost discipline
1. Identify requested scope first. Read only affected files and their direct callers/tests; inspect the tree once. Do not paste whole scenes, binaries, or broad tool results.
2. Prefer existing helpers, signals, assets and tests. Make the smallest coherent fix; no refactoring or redesign outside scope.
3. Batch independent reads and tests; avoid repeated searches, redundant status checks, duplicated plans and long explanatory output.
4. No external browsing or expensive tools when the repository already answers the question; never download/generate assets without a task reason.
5. Report only: what changed, test result, PR/merge link, and outstanding risks. Respond to the user in Turkish.

## Correctness and security
- Never trust RPC-supplied player identity, resource costs, card stats or game state; validate on the receiving side. Important decisions should be host-authoritative when architecture permits.
- All turn actions go through the server: clients call `AnaOyun.istek(...)`; the server validates with full information and broadcasts accepted moves via `hamle_uygula_rpc` in one order. Never call move handlers with `.rpc()` directly or re-add `@rpc` to them.
- Hidden information stays on the server: deck order, opponents' hands (clients hold `gizli` placeholders), battle selections before reveal, and unexplored terrain (server-only `gizli_harita_tohumu`; the explored biome is revealed with the move). Do not derive any of these from the shared match seed. Keep fog-of-war, turn order, AP, combat, economy, 7-card limits and civilization bonuses consistent on every peer.
- Mid-match rejoin: the server issues each player a secret key (`Network.donus_anahtari_rpc`); a returning client sends it via `geri_katil_rpc`, the server reserves the seat (`AnaOyun.donus_rezerve_et`) and sends a per-player masked snapshot (`_donus_goruntusu`). New match state must be added to that snapshot. Unexpected disconnects must not call PARDEX `leave_match`.
- Turn/battle time limits are server-side (`AnaOyun.tur_suresi`, `savas_secim_suresi`, `zar_suresi`); on expiry the server acts for the idle player through the same validated move path.
- Never change public RPC signatures without updating all call sites and multiplayer tests. Check simultaneous clients, disconnects and reconnect failures.
- Do not introduce nonexistent `res://` asset paths. Preserve existing visuals and mobile/desktop layout.
- New or renewed windows use `UI/HukumTheme.tres` + `UI/HukumWindow.gd`: the scalable gold frame and opaque black fill from `UI/Skins/window.svg`. Command buttons use the shared theme's 20px nine-patch skins (`Button`, `HukumPrimary`, `HukumDanger`, `HukumCompact`); never stretch complete artwork or bake text into it. See `UI/README.md`. Preserve the animated menu atmosphere and intro unless the user asks to remove them.
- Civilization cosmetics use `UI/CivilizationStyle.gd`; keep match state untouched and preserve per-civilization crests, palettes and motifs. Portraits use `UI/PortraitBorder.gd`. After changing base skin SVGs, regenerate `UI/CivilizationTemplates.gd` with `python UI/build_civilization_templates.py`.
- Never commit secrets, tokens, personal data, `.godot/` cache or generated binaries.

## Execution and verification
1. Read `git status`/current HEAD and inspect relevant code. State assumptions only where necessary.
2. Change code + focused regression for any bug. Use Godot **4.7.2 stable** when available; run:
   - `python tests/check_project.py`
   - `python tests/run_regressions.py /path/to/Godot_v4.7.2-stable_linux.x86_64`
3. For visual/scene changes, import/parse the actual Godot project and inspect affected UI when an editor is available; the isolated regression runner alone cannot verify visuals.
4. If a test cannot run, clearly mark it **not run**; never claim a green build from static inspection or old commit notes.
5. Fix failures before publishing. Never hide exceptions or remove tests merely to obtain a green result.

## GitHub delivery (user-approved workflow)
- Work on a short-lived branch based on latest `main`, commit the scoped changes, push, open a descriptive PR into `main`; no direct commits to `main`, no force-push.
- Check changed-file diff, CI and mergeability. **Squash-merge automatically only if the current task authorizes delivery, required checks pass, and no conflicts/unsafe changes remain.**
- If tests are failing, unavailable or pending, leave the PR open and report exactly why; do not silently bypass protections.
- Do not overwrite another agent's concurrent work; rebase/re-evaluate if `main` moved.
- Treat server deployment, paid service use, secrets and destructive operations as separate actions needing explicit authorization.
