# Backup and Mitigation Plan — Adventure Project

This document describes a repeatable backup procedure and a mitigation plan to prevent the build / launch issues you experienced (broken export macros, stale Intermediate/Binaries, mismatched class names/prefixes). Use it to protect the project and as runbook when problems re-appear.

## Quick summary
- I created `Backup-AdventureProject.ps1` in the project root — a PowerShell script that creates timestamped backups of key folders and a small manifest. Run it before any large changes (engine upgrades, renames, merges).
- I performed a clean build and launched the Editor successfully. Primary cause was incorrect/incorrectly-cased module export macros and mixed naming prefixes.

---

## 1) Daily/Before-Change Backup (recommended)
- Run from the project root (PowerShell):

```powershell
pwsh .\Backup-AdventureProject.ps1
```

- Optional flags:
  - `-IncludeDerivedDataCache` to include `DerivedDataCache` (large archive, rarely needed)
  - `-IncludeBinaries` to include compiled DLLs in `Binaries` (useful before binary-level changes)

Backups are stored in `backups\Adventure_backup_<timestamp>` with per-top-level zip files and a `backup_manifest.json`.

---

## 2) Immediate Mitigation steps (if you can't open/build)
1. Close the Editor and any VS instances.
2. Run a local backup (see section 1).
3. Delete or move these folders to force a clean generation: `Intermediate`, `Saved` (optionally `DerivedDataCache`, `Binaries/Win64` if you want a full clean). Example:

```powershell
Remove-Item -LiteralPath .\Intermediate -Recurse -Force
Remove-Item -LiteralPath .\Saved -Recurse -Force
```

4. Regenerate project files and do a full build using your Engine install: (adjust path if your UE is installed elsewhere)

```powershell
C:\Program Files\Epic Games\UE_5.7\Engine\Build\BatchFiles\GenerateProjectFiles.bat -projectfiles -project="$(Resolve-Path .\Adventure.uproject)" -game -engine
C:\Program Files\Epic Games\UE_5.7\Engine\Build\BatchFiles\Build.bat AdventureEditor Win64 Development -Project="$(Resolve-Path .\Adventure.uproject)" -NoHotReloadFromIDE -Verbose
```

5. If compile errors show `uses undefined class 'Adventure_API'` or similar, search for the wrong macro and replace with `ADVENTURE_API`:

```powershell
Select-String -Path .\Source\**\*.h -Pattern "Adventure_API" -SimpleMatch -List
# then edit the files, change Adventure_API -> ADVENTURE_API
```

6. If you see mixed old prefixes (`ULP_` vs `UAdventure`) reconcile the names in headers and sources to match, or restore from a previous backup where names were consistent.

---

## 3) Preventive best practices
- Avoid manual hand-editing of the export macro: create new modules/classes using Unreal Editor's New C++ Class or the `Add New C++ Class` flow; the correct `PROJECTNAME_API` macro will be added automatically.
- When renaming classes or changing public module names, do these steps:
  1. Backup.
  2. Rename header + cpp identifiers together and update include paths.
  3. Regenerate project files and build.
  4. If Blueprints reference renamed classes, open the Editor and let it fix redirectors.
- Keep your Engine installation path stable and note it in `backup_manifest.json` (the backup script writes candidate engine paths).
- Use source control (Git) with frequent commits and a protected main branch; large refactors should be done on a feature branch.

---

## 4) Recovery procedure (if build fails after renames)
1. Revert to the last good commit (preferred) or restore from `backups\Adventure_backup_<timestamp>`.
2. Re-apply renames incrementally, building after each small change.
3. Use the Editor to rename Blueprint assets (Editor handles redirectors). Do not rename assets by moving files on disk.

---

## 5) Contact / escalation
- If builds still fail after the above steps, collect the following and share:
  - `Saved\Logs\Build_*.log` and `Saved\Logs\Adventure.log`
  - The failing compiler error snippet (first 50 errors)
  - The output of `git status --porcelain` (or list of changed files)

With those I can help fix remaining code issues or create a PR with the fixes.

---

## 6) Where I saved artifacts
- `Backup-AdventureProject.ps1` — the backup script
- This document `BACKUP_AND_MITIGATION_PLAN.md` — followbook

---

## Recent actions performed (Dec 7, 2025)
- Performed a controlled cleanup of legacy `LP`-prefixed source files:
  - Created a dry-run tool `Tools/cleanup_lp_prefixes.py` to inventory `LP` files and propose safe shims/stubs.
  - Applied the safe shims/stubs and backed up originals to `Tools/backups/20251207_072613/`.
  - Attempted to replace `LP` filenames with `Adventure`-prefixed authoritative files; some intermediate renames caused UHT conflicts and were reverted.
  - Restored the original `LP` sources from the backup and ensured a stable code state.
- Created a safety branch for the work: `chore/remove-lp-shims`. Other backup branches may exist: `backup/pre-macro-fix`, `backup/pre-rename-adventure-attribute-set`.

## Where backups and artifacts are saved
- Source-level LP backups: `Tools/backups/20251207_072613/`
- Additional moved files saved to `Tools/backups/move_<timestamp>/` during intermediate steps.
- Consolidated project backups (older): `Backups/kept_20251206_092519/`.

## Recommended local verification steps (must be run locally)
1. Ensure Editor and Visual Studio are closed.
2. Clean intermediate artifacts (optional but recommended):

```powershell
Remove-Item -LiteralPath .\Intermediate -Recurse -Force
Remove-Item -LiteralPath .\Saved -Recurse -Force
```

3. Regenerate project files and build the Editor target (replace paths if your engine install differs):

```powershell
# Regenerate project files
& "C:\Program Files\Epic Games\UE_5.7\Engine\Build\BatchFiles\GenerateProjectFiles.bat" -project="C:\Unreal_Projects\Adventure\Adventure.uproject" -game -engine

# Build the Editor target
& "C:\Program Files\Epic Games\UE_5.7\Engine\Build\BatchFiles\Build.bat" AdventureEditor Win64 Development "C:\Unreal_Projects\Adventure\Adventure.uproject"
```

4. Open the Unreal Editor and run our Editor Python checks (these detect Blueprint references to legacy `LP` types and help automate safe reparenting):

```python
# In the Editor Python Console
run_file(r"C:/Unreal_Projects/Adventure/Tools/check_cbp_adventure.py")
run_file(r"C:/Unreal_Projects/Adventure/Tools/update_asc_attribute_set.py")  # dry-run first
```

5. If the Editor reports no Blueprint references to `LP` types, proceed with final removal of `LP`-shims (we recommend doing this in small batches and keeping a backup branch).

## Rollback instructions (fast)
- Restore from the LP backup folder (Tools/backups/20251207_072613/) by copying files back into `Source/Adventure/AbilitySystem/` and then rebuilding.
- Or reset the git branch to the last good commit: `git checkout <branch>; git reset --hard <commit-hash>`.

## Notes and caution
- Asset-level renames (Blueprints, UAssets) must be performed inside the Editor to preserve redirectors. Do not rename .uasset files on disk.
- The `PROJECTNAME_API` macro must use the exact project module macro `ADVENTURE_API`. Some files contained incorrect casing and were normalized during the process; review for consistency.

---

If you'd like, I can now:
- Run the backup script for you (with or without DDC/Binaries included).
- Produce a list of `LP_` occurrences across Source and Content so you can decide which to rename next.
- Create a small PR/patch with the code fixes I applied (or show the exact diffs).

Which next step do you want me to perform?
