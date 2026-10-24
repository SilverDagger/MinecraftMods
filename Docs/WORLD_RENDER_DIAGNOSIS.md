# Invisible blocks / world load review

Reviewed 2026-10-23 against the staging folders in `H:\Downloads\Minecraft\`. No actual client/server `mods` directory, runtime log, screenshot, or affected world was available. The player later reported no VulkanMod or shader pack in the affected client, removed Indium, and saw the next world load normally. That improvement is encouraging but does not prove which mod caused the earlier transient render failure. See [MOD_PROFILES.md](MOD_PROFILES.md) for the current folder layout.

The player reports that the defect appears **immediately in singleplayer** and that block backs are visible while front faces are absent. That observation strongly favors a client face-culling, shader, or graphics-backend problem over server world generation or missing terrain data.

## Earlier assembly problems, now addressed in staging

1. **Indium conflicted with Sodium.** The Indium jar required Sodium `0.5.11`, while the staged client has Sodium `0.8.13`. The user removed Indium from `Client-Only/`. Sodium has supported the Fabric Rendering API internally since 0.6. [Sodium 0.6 release notes](https://modrinth.com/mod/sodium/version/b70slbHV)
2. **Tectonic was separated from its dependency for the client profile.** Tectonic required Lithostitched, previously only in `Server-Only/`. Both now reside in `Server-Client-Optional/`. Tectonic is published as a server-side world-generation mod. [Tectonic 3.0.28 Fabric listing](https://modrinth.com/datapack/tectonic/version/WdDiEKMn)

These were **load-blocking configuration issues**, not confirmed explanations for terrain that briefly became transparent after entering a world.

## Most plausible rendering path if the world does open

- **First check Sodium's face-culling setting.** In Video Settings → Performance, turn off **Use Block Face Culling**, then reload chunks (`F3+A`) or reopen the test world. Sodium describes this setting as deciding which camera-facing block faces are submitted for rendering. A [Continuity issue](https://github.com/PepperCode1/Continuity/issues/826) documents visible faces being hidden by this setting for connected textures, although on a later Minecraft release. A fix from this toggle would identify the rendering/culling path without modifying world data.
- The client includes `sodium-fabric-0.8.13`, `iris-fabric-1.8.14-beta.1`, `continuity`, `citresewn`, `athena`, `polytone`, and `ImmediatelyFast`. This is the first group to isolate when solid blocks have hitboxes or WTHIT names but their faces do not draw. Iris now declares Sodium `0.8.x`, so the older Iris/Sodium version conflict recorded in the previous audit no longer applies.
- An [Iris issue](https://github.com/IrisShaders/Iris/issues/3214) documents fully transparent world rendering with an Iris 1.8.14 beta/Sodium combination after shader use and display changes. Its reported setup involved NeoForge and Distant Horizons, which are not the same as this staged Fabric set. It supports a **rendering-path hypothesis**, not a diagnosis of this world.
- If only modded blocks are invisible, verify that the actual client and server each loaded the same content mods from `Client-Server/` and the same versions. Examples here include Biomes O' Plenty, Chipped, Every Compat, Macaw's BOP, Supplementaries, and TerraBlender. Fabric registry sync commonly rejects missing block/item registrations when connecting, so a successful connection with invisible geometry points more strongly toward rendering or resource packs. [Fabric registry-sync discussion](https://github.com/FabricMC/fabric-api/issues/2168)
- `NEW/YungsCaveBiomes-1.21.1-Fabric-3.1.1.jar` is outside the active shared folder. If the affected world was previously generated with YUNG's Cave Biomes, establish whether the running server and client still include that mod before changing the world or saving it without the mod.
- `NEW/VulkanMod-0.6.7+1.21.1.jar` is outside the staged client folder, and the player confirmed it was not installed in the affected instance. VulkanMod is not a candidate for this observed failure.

## Fast, reversible isolation order

1. If the issue returns in the affected singleplayer world, turn off Sodium's **Use Block Face Culling** option and reload chunks (`F3+A`). Check whether the missing front faces reappear. The player confirmed no shader pack was active.
2. Check the **actual launched** client's `latest.log` for loader dependency errors, model/resource reload failures, and lines mentioning `sodium`, `iris`, `indium`, `fabric-renderer`, or the affected block's mod ID. Compare the loaded-mod list to these staging folders.
3. If the culling toggle does not fix it, test a copy of the instance without Iris, then without Sodium and its add-ons, then without Continuity/Polytone/Athena. Keep the original instance intact for comparison.
5. Determine whether an invisible block still has a collision box and WTHIT identification. Collision plus a name suggests a render/model problem; absent block data suggests a world or mod-content mismatch.

No runtime or visual check was performed; the cause of the reported invisible blocks remains unconfirmed until a log or a controlled launch result is available.
