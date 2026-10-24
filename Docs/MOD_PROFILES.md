# Minecraft mod folder profiles

Updated 2026-10-23 for the 1.21.1 Fabric pack. These directories are staging folders beside each other in `H:\Downloads\Minecraft\`; they are not Minecraft's live `mods` folder.

| Folder | Meaning | Current jars |
| --- | --- | ---: |
| `Client-Server/` | Shared content and libraries for both sides | 52 |
| `Client-Only/` | Client UI, maps, and rendering | 37 |
| `Server-Client-Optional/` | Datapack-style world generation and structures for the server; optional on the client for singleplayer, with their required libraries | 16 |
| `Server-Only/` | Server-targeted tools, optimizations, and gameplay rules; generally omit from the client profile | 12 |

Assemble a **multiplayer server** from `Client-Server/` + `Server-Client-Optional/` + `Server-Only/`. Assemble a **multiplayer client** from `Client-Server/` + `Client-Only/`. For **singleplayer**, add the desired datapack-style features from `Server-Client-Optional/` to the client. Keep each feature's dependencies with it; for example, Tectonic and CTOV depend on Lithostitched, and the YUNG's structure mods depend on YUNG's API and Cloth Config. `NEW/` and `Creative/` are separate selections, outside these three base profiles.

`Server-Client-Optional/` is deliberately narrow: Tectonic, CTOV, Village Nullifier, YUNG's 11 structure mods, and the Lithostitched and YUNG's API libraries needed for them. Installing optional worldgen mods in a singleplayer profile changes new world generation; keep the same selection when reopening that world.

`Server-Only/` contains AutoChunky, BlueMap, C2ME, Chunky, Craft Saddles, Fabric Carpet, Leaves Us in Peace, NetherPortalFix, RecipeCooldown, ServerCore, Smarter Farmers, and SmoothChunk. Some of these jars can physically load in singleplayer, but this profile treats them as server-targeted rather than optional datapack-style client additions. AutoChunky specifically declares `environment: "server"`, which Fabric defines as the physical dedicated server and [excludes singleplayer and LAN](https://docs.fabricmc.net/develop/loader/fabric-mod-json).

The stricter resort moved 10 jars from `Server-Client-Optional/` back to `Server-Only/` on 2026-10-23. Classification was checked against the jars' Fabric metadata, including Tectonic's Lithostitched dependency and AutoChunky's server-only environment. No game launch was performed after sorting.
