# Adventure — Project Overview and GAS Integration

This repository contains the Adventure project (Unreal Engine). This README provides a high-level Project Design Document, product backlog, sprint backlog, WIP items, bottlenecks, and Done checklist focused on the recent Gameplay Ability System (GAS) integration using a PlayerState-owned ASC.

---

## Project Design Document (High Level)

**Goal**
- Add a robust Gameplay Ability System (GAS) to Adventure that supports networked multiplayer, persistent player-state abilities, and clear authoring workflow for designers (via Blueprints).

**Architecture (concise)**
- PlayerState-owned Ability System Component (ASC): Abilities and AttributeSets persist across pawn respawns and possession changes.
- Character (pawn) is responsible for initializing ASC actor info on possession and replication.
- ASC subclass `UAdventureAbilitySystemComponent` provides helper methods (EnsureAttributeSet, GetAdventureAttributeSet).
- `UAdventureAttributeSet` holds replicated attributes (Health example implemented).
- Gameplay Abilities implemented as `UGameplayAbility` subclasses (sample `UGA_SampleAbility` provided).

**Key code locations**
- `Source/Adventure/Public/AbilitySystem/` — public ASC and AttributeSet headers
- `Source/Adventure/AbilitySystem/` — ASC and AttributeSet implementation and sample abilities
- `Source/Adventure/Public/Player/AdventurePlayerState.h` and `Source/Adventure/Player/AdventurePlayerState.cpp` — PlayerState owns ASC and grants abilities
- `Source/Adventure/Public/Characters/AdventureCharacter.h` and `Source/Adventure/Characters/AdventureCharacter.cpp` — Character initializes ASC actor info and calls PlayerState to grant abilities

**Non-functional requirements**
- Works in networked PIE (server + clients)
- Abilities granted server-side only
- Attributes replicate to clients and have OnRep hooks where appropriate

---

## Product Backlog (candidate features)
- Core GAS wiring (PlayerState ASC, AttributeSet, Character init) — Done
- Ability input wrappers and BP-friendly helpers — In progress / Sprint candidate
- GameplayAbility examples (damage, heal, buff) — backlog
- Designer-facing docs and Blueprints for abilities/attributes — backlog
- In-game HUD for attributes (health) — backlog
- Persistent unlocks and progression stored in PlayerState or external systems — backlog

---

## Sprint Backlog (current sprint)
- Create `BP_AdventurePlayerState` and assign default abilities (High)
- Reparent `CBP_AdventureCharacter` to `AAdventureCharacter` and migrate logic (High)
- Wire input → ability activation in Character BP (High)
- QA smoke tests in multiplayer PIE (High)
- Add simple debug logs for ASC flow (Medium)

Estimates: focus on core items (approx 5–7 story points)

---

## WIP (work in progress)
- Character/BP migration and input wiring
- Optional C++ wrapper for blueprint-activation (recommend implementing this sprint)

---

## Bottlenecks / Risks
- UHT and header include order: keep public headers only under `Source/<Module>/Public/*` to avoid duplicate name conflicts.
- Replication timing: `InitAbilityActorInfo` must run before granting abilities; use `PossessedBy` on server and `OnRep_PlayerState` on clients.
- Asset pipeline: Blueprints (.uasset) cannot be created by script here; a designer must perform Editor steps.
- Multiplayer QA requires running PIE with multiple clients to validate replication.

---

## Done (Definition of Done for GAS feature)
- C++ ASC & AttributeSet implemented and compiled (done)
- PlayerState owns ASC and grants abilities server-side (done)
- Character initializes ASC actor info on possession and replication (done)
- Sample GameplayAbility (`UGA_SampleAbility`) present and activatable (done)
- Editor steps documented and a BP PlayerState recipe provided (docs added in `docs/README_GAS.md`)
- Backup created before changes (Backups/backup_YYYYMMDD_HHMMSS)

---

## How to build (quick)
See original instructions. Use your installed UE path. Example:

```powershell
& "C:\Program Files\Epic Games\UE_5.7\Engine\Build\BatchFiles\Build.bat" AdventureEditor Win64 Development "C:\Unreal_Projects\Adventure\Adventure.uproject" -waitmutex
```

---

## Contacts and ownership
- Gameplay / GAS: TODO assign owner
- Character/BP migration: TODO assign owner
- QA: TODO assign owner

---

## Camera System Updates (new)

The project now includes an editor authoring utility and runtime camera manager that allow designers to create camera assets (FirstPerson, ThirdPerson, TopDown rigs) and smoothly transition between them with the mouse wheel.

See docs/README_CameraSystem.md for usage, testing, and implementation details.

---

### Editor Python: reparent_assets.py

We've added `Content/Python/reparent_assets.py` — a small Editor-only helper to create new child Blueprints that inherit from a requested parent. Important notes:

- This script must be executed inside the Unreal Editor Python environment (the `unreal` module is provided by the Editor). Running it with the system Python shows `ModuleNotFoundError: No module named 'unreal'`.

How to run it (Designer / QA):
1. Open the Adventure project in the Unreal Editor.
2. Window -> Developer Tools -> Python Console.
3. In the Console type:
   exec(open(r"C:/Unreal_Projects/Adventure/Content/Python/reparent_assets.py").read())

Or run the Editor from the command line with:

```powershell
& "C:\ Program Files\Epic Games\UE_5.7\Engine\Binaries\Win64\UnrealEditor.exe" \
  "C:\Unreal_Projects\Adventure\Adventure.uproject" -run=pythonscript -script="C:/Unreal_Projects/Adventure/Content/Python/reparent_assets.py"
```

If you see `ModuleNotFoundError: No module named 'unreal'` or "No Python interpreter configured for the module":
- That means you're running the script in your system Python (outside the Editor). Run it from the Editor as shown above.
- If you need to run Editor Python from command-line, ensure you launch `UnrealEditor.exe` with the `-run=pythonscript -script=...` flags.

Designer test checklist (quick):
- Open Editor, run the script from Python Console.
- Confirm new assets were created under the same package path with `_Reparented` suffix.
- Open created Blueprint(s) — verify parent class in Class Settings -> Parent Class.
- If anything fails, check the Editor log (Window -> Developer Tools -> Output Log) for warnings/errors from `reparent_assets.py`.

---

For more detailed Editor step-by-step guidance on wiring PlayerState-owned ASC and running QA tests, see `docs/README_GAS.md`.

---

**Repository transfer**
- This repository was transferred from user `freelundin` to the organization `Nola-Developer-Incubator` on 2025-12-12.
- Canonical repository URL: https://github.com/Nola-Developer-Incubator/Adventure
- If you previously cloned from `freelundin/Adventure`, update your local remote to point to the organization (examples below).

**Contributing / Clone (quick start)**
- Clone via SSH (recommended if you have an SSH key registered with GitHub):

```powershell
# Clone (SSH)
git clone git@github.com:Nola-Developer-Incubator/Adventure.git
```

- Clone via HTTPS:

```powershell
# Clone (HTTPS)
git clone https://github.com/Nola-Developer-Incubator/Adventure.git
```

- If you have an existing local clone that points to the old remote, update the origin URL:

```powershell
# SSH
cd C:\Unreal_Projects\Adventure
git remote set-url origin git@github.com:Nola-Developer-Incubator/Adventure.git
# or HTTPS
git remote set-url origin https://github.com/Nola-Developer-Incubator/Adventure.git
```

**Git LFS (important for Unreal assets)**
- This project uses Git LFS for large binary assets. Before fetching or pushing, install and enable Git LFS:

```powershell
# Install (choose method you prefer, e.g., choco, winget, or installer)
# choco install git-lfs
# or winget install --id Git.GitLFS

git lfs install
# After cloning, fetch LFS objects:
git lfs pull
```

See `scripts/README.md` for helper scripts created during the transfer process (transfer preview, remote update, and LFS push helpers).
