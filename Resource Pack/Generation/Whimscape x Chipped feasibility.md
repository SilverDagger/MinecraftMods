# Whimscape x Chipped feasibility

Assessment of the installed `Mods/Individual/Client-Server/chipped-fabric-1.21.1-4.0.2.jar` against `Resource Pack/Raw/Whimscape_1.20.2-1.21.11_r7.zip`. No Chipped add-on was built.

## Decision

A broad Biomes O' Plenty-style pass is technically possible as a resource-pack override, but is not worthwhile under the current rule of transferring existing Whimscape patterns without inventing new art. Chipped's variants *are* different patterns: replacing them with the vanilla Whimscape textures would remove the visual difference that identifies each Chipped block. Keeping the Chipped designs and merely recoloring them to match Whimscape is a different, much larger art project.

## Evidence from the installed JAR

| Asset type | Count | Consequence |
| --- | ---: | --- |
| Chipped blockstates | 6,981 | Much wider scope than the 429 Biomes O' Plenty blockstates reviewed for the current add-on. |
| Chipped block PNGs | 12,040 | 7,362 standard PNGs and 4,678 under `ctm/`. |
| Chipped block models | 9,839 | 9,830 reference a Chipped texture. Only 332 also reference a vanilla Minecraft texture, so Whimscape's existing vanilla assets affect some model components but do not style the whole block. |
| Athena loader blockstates | 1,427 | Includes 896 `athena:ctm` states, plus pillar, giant, pane, and carpet loaders. A connected design must keep its full tile set consistent. |
| Whimscape Chipped assets | 0 | The base pack contains no `assets/chipped/` override. |

Only 12 top-level Chipped block PNG basenames exactly match a Whimscape vanilla block PNG basename. All 12 pairs have the same 16×16 dimensions, but their artwork is visibly different. For example, Chipped's `end_stone_bricks`, `mud_bricks`, and `prismarine_bricks` have different joints or ornamentation from Whimscape's versions. A direct copy would make those Chipped variants look like the vanilla blocks instead of adapting their distinct design. [Comparison sheet](Whimscape%20x%20Chipped-feasibility-preview.png) shows all 12 pairs; it is a research preview, not an adapted pack.

Chipped's `pegged_oak_planks` and `bordered_stone` demonstrate another constraint: each uses a normal model texture and an Athena blockstate that names four connected tiles (`empty`, `horizontal`, `vertical`, and `center`). A one-PNG replacement would leave inconsistent edges. Doors, trapdoors, panes, leaves with fruit or frost, carved blocks, and animated textures have their own shape and state constraints.

## Sensible boundary if revisited

Keep Chipped's own texture patterns. A small, separately approved prototype could harmonize the palette of **one** construction family, including every texture used by its models and connected-texture states, then compare it in game beside Whimscape vanilla blocks. This would test whether palette matching is enough without claiming that Whimscape patterns have been transferred. It should not be expanded across Chipped automatically; review each motif and exclude any design that needs hand drawing or loses its identity.

The [Chipped project page](https://modrinth.com/project/BAscRYKm) describes its textures as hand made and its connected textures as Athena powered. It lists the project as all rights reserved, so distribution of an add-on that incorporates modified Chipped artwork should also be checked against the creator's permissions.
