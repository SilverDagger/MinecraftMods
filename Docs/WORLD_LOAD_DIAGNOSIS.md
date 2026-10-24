# Singleplayer world load diagnosis (2026-10-23)

Source: `C:\Users\hunte\AppData\Roaming\.minecraft\logs\latest.log`, session around 21:10–21:14. Only top-level jars in the live `mods` directory were counted; archival subfolders were ignored. All 110 active jars matched one of the sorted folders under `H:\Downloads\Minecraft` by filename.

## Confirmed findings

- At log line 4603, ModernFix reports a single integrated-server tick taking over 40 seconds. The server thread in that watchdog dump (lines 5593–5643) is rebuilding creative item groups through Every Compat and Moonlight while Sawmill refreshes/sends its recipe order on player connect. The log later reports a 78,771 ms delay (about 79 seconds) at line 6690. This establishes a severe startup stall, not a fatal crash cause.
- At lines 619–620, Every Compat itself warns that Chipped adds enough blocks to cause an explosion in the amount of generated content. This makes the Every Compat + Chipped combination a strong suspect for the stall; Sawmill is the caller that exposed the expensive rebuild in this thread dump.
- `mcwbiomesoplenty-fabric-1.21.1-1.6.jar` produces 91 `Unable to bake model` warnings (starting line 4020) and roughly 287 error lines for its loot-table data around line 4213. Its affected blocks may render incorrectly or have broken drops. This does not by itself establish that ordinary terrain faces disappear.
- Diagonal Windows warns about 198 Every Compat/Chipped glass pane models that need exclusion via its `non_diagonal_windows` tag (starting line 3826). This is another specific rendering compatibility issue for those panes.
- Mod Menu's update checker throws a background `ConcurrentModificationException` near line 571. The log does not link it to world loading.
- The session ends with an integrated-server stop and successful saves of all dimensions. No 2026 crash report or `hs_err_pid` file was found in the checked Minecraft paths. The reported crash may have been a hang/forced close or may have a launcher/native report elsewhere.

## Safe test order

Use a new temporary world or a copy of the affected save for each test. Removing block-adding mods from an original save and then saving can remove or replace their content.

1. Temporarily disable **Every Compat** in the test instance, keeping Chipped and Sawmill. If the long world-entry stall goes away, Every Compat's generated content is implicated. Restore it after the test.
2. If the stall remains, restore Every Compat and temporarily disable **Sawmill** for a separate test. This tests the player-connect recipe sync path.
3. Temporarily disable **Macaw's Biomes O' Plenty** add-on (`mcwbiomesoplenty`) in a separate test if broken modded block models remain. This tests the 91 model failures and loot-table errors.
4. If vanilla terrain still has missing faces after the stall is gone, investigate the rendering stack separately (Sodium, Iris, Continuity, and culling mods), one change at a time. The current watchdog dump does not prove a rendering-mod defect.

Keep a fresh `latest.log` from any reproduction. If the launcher reports a fatal exit, collect its exit code and any new crash report so it can be distinguished from the confirmed startup stall.
