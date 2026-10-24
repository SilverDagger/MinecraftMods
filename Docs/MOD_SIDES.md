# Mod sides for this folder

Assumption: this is a **Minecraft 1.21.1 Fabric** multiplayer pack. "Server only" means the jar belongs on the dedicated server and clients do not need it to join. "Client only" means it belongs in each player's client mods folder and not on the dedicated server. A mod in neither list may need to be on **both** sides, or may be an optional optimization/library on either side. Do not infer "both required" just from Fabric's `environment: "*"` field.

## In `Server-Only/`

- AutoChunky
- BlueMap
- C2ME (server chunk-generation optimization)
- Chunky (pregeneration commands)
- Craft Saddles
- Fabric Carpet (client installation is optional for some tools)
- Leaves Us in Peace
- Lithostitched (world-generation dependency for CTOV)
- NetherPortalFix
- RecipeCooldown
- ServerCore
- Smarter Farmers
- SmoothChunk
- Village Nullifier
- YUNG's Better Desert Temples, Better Dungeons, Better End Island, Better Jungle Temples, Better Mineshafts, Better Nether Fortresses, Better Ocean Monuments, Better Strongholds, Better Witch Huts, Bridges, and Extras
- ChoiceTheorem's Overhauled Village (`[Fabric]ctov`)

YUNG's **Cave Biomes** is an exception: it adds new biome content and belongs on both sides, along with its applicable dependencies. **YUNG's API therefore stays in the root** for this pack.

## In `Client-Only/`

- Advancements Reloaded
- Athena (needed by Chipped's connected textures)
- Bad Packets, if it is used only for WTHIT in this pack
- Chest Tracker
- CIT Resewn
- Continuity
- Entity Culling
- Entity Model Features
- Entity Texture Features
- JEI
- JMI (JourneyMap integration)
- JourneyMap (server installation is optional for server features)
- Lightweight Inventory Sorting
- Litematica
- MaLiLib
- Pick Up Notifier
- Polytone
- ShulkerBoxTooltip
- WTHIT (server installation is optional for extra data)
- Yet Another Config Lib v3 (YACL)

Keep Cloth Config available on the server: the YUNG's structure jars in this folder explicitly list `cloth-config2` as a dependency. Ping Wheel belongs on **both** sides for multiplayer pings. The rest of the gameplay/content mods and their libraries should stay in the shared/both-side set unless a particular mod's documentation says otherwise. Fabric API and Fabric Language Kotlin should be supplied on whichever side has a dependent mod.

The jars listed above were sorted on 2026-10-23: 26 server-only and 20 client-only. The side folders are now siblings of `Client-Server/` under `H:\Downloads\Minecraft\`. The root holds shared mods and the incompatible jars noted below pending replacement.

## Fix before trying to launch the pack

- `EchoChest-v21.11.1-mc1.21.11-Fabric.jar`, `FarmersDelight-1.21.11-3.6.16+refabricated.jar`, and `friendsandfoes-fabric-5.0.3+mc1.21.11.jar` target **1.21.11**, not 1.21.1. The current Flowery Mooblooms jar depends on Friends & Foes, so get a matching 1.21.1 build of that dependency.
- `litematica-fabric-26.1.2-0.27.14.jar` declares Minecraft `~26.1-`, not 1.21.1; its declared MaLiLib minimum is also newer than the MaLiLib jar here. Replace both with matching 1.21.1 builds if Litematica is wanted.
- `tectonic-3.0.28-neoforge-21.1.jar` and `TerraBlender-neoforge-1.21.1-4.1.0.8.jar` are **NeoForge** jars, not Fabric jars. Biomes O' Plenty and YUNG's Cave Biomes require a compatible **Fabric** TerraBlender jar.
- Other declared dependencies not visible as standalone jars include `whereisit` (Chest Tracker), `diagonalblocks` (Diagonal Fences/Windows), `iteminteractions` (Easy Shulker Boxes), `extensibleenums` (Ender Zoology), `apollib` (Lithostitched), `addonslib` (Macaw's BOP), and `geckolib` (YUNG's Cave Biomes). Some dependencies may be bundled inside jars; check the loader's dependency report before downloading replacements.

Basis: local jar names and `fabric.mod.json` metadata inspected on 2026-10-23; side behavior cross-checked against [YUNG's Better Dungeons](https://modrinth.com/mod/yungs-better-dungeons), [Athena](https://modrinth.com/mod/athena-ctm), [Ping Wheel](https://modrinth.com/mod/ping-wheel), and [Lightweight Inventory Sorting](https://modrinth.com/mod/lightweight-inventory-sorting).

## First `Unvalidated/` update audit: creative server copies

On 2026-10-23, 94 jars were removed from `Unvalidated/` because the same mod appeared in the root, `Client-Only/`, or `Server-Only/`. Matching used Fabric mod IDs, with known ID changes for Balm (`balm-fabric` to `balm`) and Ping Wheel (`ping-wheel` to `pingwheel`). Tectonic and TerraBlender were matched by project name because their root jars use NeoForge metadata.

Five jars remain for sourcing/review:

- `chunky-player-pause-1.0.1.jar`
- `effortlessbuilding-4.2+1.21.1.jar`
- `mcwfurnituresbop-fabric-1.21.1-1.1.jar` — a separate Macaw's Furniture/BOP compatibility project from the root's broader Macaw's BOP jar.
- `tooltipfix-1.1.1-1.20.jar` — filename indicates a 1.20 build; check compatibility before use.
- `worldedit-mod-7.3.8.jar`

This audit recorded whether a mod had another sourced jar, **not** whether that jar worked in this pack. In particular, the old Fabric Tectonic and TerraBlender jars were removed from `Unvalidated/`, while the root held NeoForge builds that cannot load in Fabric. The root also held 1.21.11 builds of Echo Chest, Farmer's Delight, and Friends & Foes.

## Second `Unvalidated/` update audit: local client copies

After the folders moved to `H:\Downloads\Minecraft\`, a new set of 93 local-client jars was placed in the sibling `Unvalidated/` folder. On 2026-10-23, 71 were removed because the same mod appeared in `Client-Server/`, `Client-Only/`, or `Server-Only/`. This included Balm and Ping Wheel ID changes, and TerraBlender matched by project name because the root build uses NeoForge metadata.

The 22 jars left in `Unvalidated/` are:

- `bobby-5.2.4+mc1.21.jar`
- `chat_heads-0.13.7-fabric-1.21.jar`
- `CompletionistsIndex-v21.1.0-1.21.1-Fabric.jar`
- `concentration-fabric-1.21-2.3.0.jar`
- `DistinguishedPotions-v21.1.0-1.21.1-Fabric.jar`
- `dynview-fabric-1.21-4.0.jar`
- `effortlessbuilding-4.2+1.21.1.jar`
- `everycomp-1.21-2.8.0-fabric.jar`
- `HangGlider-v21.1.0-1.21.1-Fabric.jar`
- `ImmediatelyFast-Fabric-1.3.3+1.21.1.jar`
- `indium-1.0.35+mc1.21.jar`
- `iris-fabric-1.8.1+mc1.21.1.jar`
- `jeed-1.21-2.2.9-fabric.jar`
- `mcwfurnituresbop-fabric-1.21.1-1.1.jar`
- `modmenu-11.0.3.jar`
- `optigui-2.3.0-beta.6+1.21.jar`
- `PlentyPlates-v21.1.0-1.21.1-Fabric.jar`
- `reeses-sodium-options-fabric-1.8.0+mc1.21.3.jar`
- `Simple-Block-Overlay 1.21-fabric-1.4.3.jar`
- `SlotCycler-v21.1.1-1.21.1-Fabric.jar`
- `sodium-extra-fabric-0.6.0+mc1.21.1.jar`
- `sodium-fabric-0.6.3+mc1.21.1.jar`

The root's TerraBlender build remains NeoForge, so a compatible Fabric build still needs to be sourced. The `reeses-sodium-options` filename indicates Minecraft 1.21.3; verify its compatibility before treating it as a 1.21.1 candidate.

## `Unsorted/` side sorting

On 2026-10-23, all 20 jars in the sibling `Unsorted/` folder were moved: 17 to `Client-Only/`, 3 to `Client-Server/`, and none to `Server-Only/`.

The shared jars are `everycomp-1.21-2.11.55-fabric.jar`, `hauntedharvest-1.21-3.5.1-fabric.jar`, and `PlentyPlates-v21.1.0-1.21.1-Fabric.jar`. They add content or gameplay behavior for both sides. The other 17 are client display, UI, or rendering mods, including Distinct Potions, JEED, Simple Block Overlay, Iris, Sodium, and their related client tools.

Sorting by side does **not** resolve version conflicts. The sorted `iris-fabric-1.8.8+mc1.21.1.jar` declares Sodium `0.6.x`, `indium-1.0.35+mc1.21.jar` declares Sodium `0.5.11`, and `sodium-fabric-0.8.13+mc1.21.1.jar` is the only standalone Sodium jar in the client folder. These three cannot satisfy each other's declared versions as currently assembled. Slot Cycler's `hotbarslotcycling` dependency is bundled inside its own jar.

Side behavior was checked against local `fabric.mod.json` metadata and the project pages for [Distinct Potions](https://modrinth.com/project/distinct-potions), [Simple Block Overlay](https://modrinth.com/mod/simple-block-overlay), [Every Compat](https://modrinth.com/mod/every-compat), [Haunted Harvest](https://modrinth.com/mod/haunted-harvest), and [Plenty Plates](https://modrinth.com/user/Fuzs).
