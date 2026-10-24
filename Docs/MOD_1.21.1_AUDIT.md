# Minecraft 1.21.1 mod compatibility flags

> Historical snapshot: several flagged jars were replaced after this scan. For the current folder contents and world-rendering review, see [WORLD_RENDER_DIAGNOSIS.md](WORLD_RENDER_DIAGNOSIS.md).

Scanned on 2026-10-23 for a Minecraft **1.21.1 Fabric** pack. Scope: the 125 top-level jars in `H:\Downloads\Minecraft\Client-Server\`, `Client-Only\`, `Server-Only\`, `Creative\`, and `NEW\`. The scan checked jar filenames, `fabric.mod.json` Minecraft requirements, non-Fabric loader metadata, and author release listings where the filename and metadata disagreed. This is a version and loader audit, not a launch test.

## Wrong Minecraft version

| Jar | Folder | Finding |
| --- | --- | --- |
| `journeymap-fabric-1.21.11-6.0.0.jar` | `Client-Only` | Published for **1.21.11**, not 1.21.1. Its internal Fabric requirement (`>=1.20.6`) is too broad to catch this. Replace it with a JourneyMap Fabric release explicitly listed for 1.21.1. |

The [JourneyMap release listing](https://modrinth.com/plugin/journeymap/version/1.21.11-6.0.0%2Bfabric) identifies this build as Minecraft 1.21.11.

## Correct game line, wrong loader for Fabric

| Jar | Folder | Finding |
| --- | --- | --- |
| `tectonic-3.0.28-neoforge-21.1.jar` | `Client-Server` | NeoForge jar; has NeoForge metadata and no `fabric.mod.json`. Requires a Fabric build for this pack. |
| `TerraBlender-neoforge-1.21.1-4.1.0.8.jar` | `Client-Server` | NeoForge jar; has NeoForge metadata and no `fabric.mod.json`. A Fabric TerraBlender jar is also present in this folder, so the NeoForge copy should not be included when assembling the Fabric mods directory. |

## 1.21.1 jars with incompatible mod dependencies

These are **not** wrong Minecraft-version downloads, but they prevent this client set from satisfying its own declared mod requirements:

| Jar | Declared Sodium requirement | Installed Sodium |
| --- | --- | --- |
| `indium-1.0.35+mc1.21.jar` | `0.5.11` | `0.8.13+mc1.21.1` |
| `iris-fabric-1.8.8+mc1.21.1.jar` | `0.6.x` | `0.8.13+mc1.21.1` |

Indium's [author release listing](https://www.curseforge.com/minecraft/mc-mods/indium/files/5632454) explicitly includes Minecraft 1.21.1, so its problem here is the Sodium version.

## Filename checked and cleared

- `tooltipfix-1.1.1-1.20.jar` is listed by its author for Minecraft **1.20 through 1.21.1**. The `1.20` suffix alone is not a reason to remove it. [ToolTipFix release listing](https://www.curseforge.com/minecraft/mc-mods/tooltipfix/files/all?page=1)
- `worldedit-mod-7.3.8.jar` does not declare a Minecraft dependency in its Fabric metadata, but its [author release page](https://www.curseforge.com/minecraft/mc-mods/worldedit/files/5830452) lists Fabric/NeoForge support for **1.21–1.21.1**.
- Other filenames containing only `1.21` were not flagged solely on that suffix when their declared Minecraft range included 1.21.1.
