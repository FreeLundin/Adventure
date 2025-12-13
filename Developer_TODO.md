# Developer TODO — Adventure Project

This TODO lists tasks to stabilize the project, finish the LP -> Adventure_ migration, and implement a simple UI widget along with steps to test it.

Top-level goals
- Ensure project builds clean on UE 5.7 and Visual Studio 2026.
- Finish renaming and cleanup (LP -> Adventure_ prefix) only where safe and necessary.
- Add a minimal UMG Widget C++ class so designers can create a Blueprint subclass and iterate in the Editor.
- Add CI/build automation guidance.

Tasks (priority order)
1. Backup (Required)
   - Run `pwsh .\Backup-AdventureProject.ps1 -IncludeBinaries $true` and store backup externally.

2. Verify Build Dependencies (Required)
   - Confirm `Adventure.Build.cs` contains `UMG`, `Slate`, `SlateCore` (done).
   - Build Editor target: ensure no compile errors.

3. Code consistency (High)
   - Search for `Adventure_API` occurrences and change to `ADVENTURE_API` (done where identified).
   - Create a small mapping list of old class names (ULP_*) -> new names to apply where safe.
   - For each rename: update header, cpp, and references; run build.

4. Asset renames (Medium)
   - List `BP_LP_*` Blueprints in `Content/` and decide rename strategy. Best practice: rename inside Editor and fix redirectors.

5. Add UI widget (Done: `UAdventureWidget`).
   - Create UMG Blueprint from `UAdventureWidget` (right-click -> Create Widget Blueprint) and add a TextBind to `TitleText`.
   - Place widget on screen using a simple HUD or PlayerController to test.

6. Automation & CI (Optional)
   - Add a GitHub Actions workflow to run UBT build script for PR validation.

7. Documentation & onboarding (Optional)
   - Update README with engine version, build steps, and the rename policy.

Notes & risks
- Renaming classes and assets is risky. Always backup and test small batches.
- Assets reference names internally — prefer editor-level rename to maintain redirectors.

Local testing steps for new widget
1. Build project in Visual Studio or run Build.bat for AdventureEditor.
2. Open Editor, right-click Content -> Create Basic Asset -> User Interface -> Widget Blueprint. Choose parent `AdventureWidget`.
3. Open the widget, add a Text block, bind its Text to `TitleText` (Expose on Spawn or via Get TitleText).
4. Make a simple level BP or PlayerController that creates and adds the widget to viewport on BeginPlay.

If you want, I can:
- Run the backup now.
- Run a project-wide search for `LP_` or `Adventure_API` occurrences and produce a report.
- Create a small sample PlayerController C++ to add the widget to viewport automatically on BeginPlay.

Choose which of these you'd like me to do next.

## Recent actions (Dec 7, 2025)
- Performed an `LP`-prefix cleanup dry-run and applied safe shims/stubs. Original LP files are backed up in `Tools/backups/20251207_072613/`.
- A temporary branch `chore/remove-lp-shims` was used for this work; the LP files were restored to a stable state after an intermediate rename attempt that caused UHT errors.

## What to test locally (priority)
1. Full clean build
   - Remove Intermediate/Saved, regenerate project files, and build AdventureEditor (see BACKUP_AND_MITIGATION_PLAN.md for exact commands).
2. Editor verification
   - Open the Editor and run Python checks:
     - `Tools/check_cbp_adventure.py` — verifies CBP_Adventure character blueprints and reports reparenting needs.
     - `Tools/update_asc_attribute_set.py` — dry-run for ASC attribute-set references.
3. Widget test (UX/UI) — smoke test
   - Create a Widget Blueprint that derives from `UAdventureWidget` and add it to the viewport on BeginPlay in `PC_Adventure` (or sample PlayerController) to verify UMG binding.

## If build fails with UHT / macro issues
- Ensure `ADVENTURE_API` is used consistently (case-sensitive) in header declaration lines.
- Revert to backup branch (`backup/pre-macro-fix`) if needed and inspect the changes in `Tools/backups/`.
