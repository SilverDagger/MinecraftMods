# Whimscape x Biomes o Plenty

`Resource Pack/Raw/Whimscape x Biomes o Plenty.zip` is a separate Minecraft 1.21.1 resource pack. Load it above Whimscape. The SUCCU merge order puts it immediately after the Whimscape base. It targets Biomes O' Plenty Fabric 1.21.1 `21.1.0.14` and pack format 34.

## Scope

The wood portion covers the 13 Biomes O' Plenty wood families: dead, empyreal, fir, hellbark, jacaranda, magic, mahogany, maple, palm, pine, redwood, umbran, and willow. It replaces planks, logs and stripped logs, doors, trapdoors, buttons, fences, boat and chest boat textures, sign textures, and their inventory icons. Whimscape's three plank variations and its button, fence, and door models are adapted to Biomes O' Plenty. Slabs, stairs, fence gates, pressure plates, and wood blocks use those same wood textures through the mod's existing models. A small set of plants is covered below; saplings remain in their original style.

The generated pixels come from Whimscape's vanilla wood textures. For each part, the generator uses the corresponding Biomes O' Plenty texture as the color reference while retaining the placement, transparency, and light/dark pixel pattern from Whimscape. Whimscape's crimson and warped stems are animated sheets; the generator uses their first frame for the static Biomes O' Plenty logs.

[Wood preview](Whimscape%20x%20Biomes%20o%20Plenty-preview.png) shows the generated plank, log, stripped log, and door colors at enlarged pixel scale. The [original Biomes O' Plenty preview](Whimscape%20x%20Biomes%20o%20Plenty-original-preview.png) uses the same layout and scale for comparison.

| Biomes O' Plenty wood | Whimscape pattern |
| --- | --- |
| Dead | Pale oak |
| Empyreal | Crimson; dark oak for boats |
| Fir | Spruce |
| Hellbark | Dark oak |
| Jacaranda | Pale oak |
| Magic | Warped; oak for boats |
| Mahogany | Cherry |
| Maple | Oak |
| Palm | Birch |
| Pine | Spruce |
| Redwood | Mangrove |
| Umbran | Dark oak |
| Willow | Birch |

## Stone and terrain

The second pass covers 59 block IDs in the installed Biomes O' Plenty JAR. The 62 new PNGs cover their shared textures, including the inventory view of thermal calcite. Related slabs, stairs, and walls use the same base textures through Biomes O' Plenty's models.

| Family | Block IDs | Treatment |
| --- | ---: | --- |
| Black, white, and orange sand and sandstone | 33 | Whimscape sand, sandstone, cut, and chiseled patterns recolored to each Biomes O' Plenty palette. Sand gets Whimscape's three weighted variants. Smooth sandstone uses the recolored sandstone top, as the mod's models already specify. |
| Brimstone and its bricks, bud, cluster, and fumarole | 9 | Whimscape netherrack and nether brick patterns for cubes; distinctive bud, cluster, and fumarole shapes retained with adjusted contrast. |
| Blackstone bulb and spines | 2 | Original cross-shaped silhouettes retained, with contrast adjusted against Whimscape blackstone. |
| Thermal calcite and vent | 2 | All five distance-based textures for each block, plus the inventory texture, retained and contrast-adjusted against Whimscape calcite. |
| Rose quartz block, cluster, and three buds | 5 | Whimscape amethyst pattern for the solid block; original crystal silhouettes retained for cluster and buds. |
| Algal, null, and unmapped End stone | 3 | Algal and null overlays retained and adjusted against Whimscape End stone. Unmapped End stone already reads the vanilla End stone texture, so it needs no new PNG. |
| Dried salt, mossy black sand, glowing moss block and carpet, origin grass block | 5 | Whimscape sand pattern for salt; original moss overlays retained; Whimscape grass patterns recolored separately for green grass, snowy edge, and dirt. The glowing moss carpet shares the block texture. |

[Stone comparison preview](Whimscape%20x%20Biomes%20o%20Plenty-stone-preview.png) pairs a representative original Biomes O' Plenty texture with its new texture. The full 59-block coverage is checked against blockstate and model references, not just the examples in the preview.

## Leaves and leaf piles

The leaf pass covers 22 leaf blockstates and the three colored maple leaf piles. Twenty ordinary leaf textures use Whimscape foliage patterns with Biomes O' Plenty colors. Magic's alternate leaf texture uses Whimscape's oak leaf variation. Jacaranda and snowblossom keep their separate foliage and blossom colors. Flowering oak and pine retain their original flower/needle overlays, and mossy willow retains its moss texture and overlay, with contrast adjusted to the related Whimscape foliage. Null leaves now have two dedicated Whimscape-pattern leaf textures and models instead of borrowing the null End-stone overlays. Rainbow birch already references `minecraft:block/birch_leaves`, so it takes Whimscape's birch leaf texture through the base pack.

The maple leaf piles retain their original pile silhouettes with Whimscape-like contrast. Their three inventory icons are included. Leaf PNGs carry Whimscape's `dark_cutout` mipmap metadata where applicable. [Leaf comparison preview](Whimscape%20x%20Biomes%20o%20Plenty-leaves-preview.png) shows all adapted leaf families and piles beside their original textures.

## Conservative plant matches

Seven more block IDs have close Whimscape counterparts with compatible Biomes O' Plenty models. The generator takes the Whimscape pixel pattern and applies the Biomes O' Plenty colors. The rose uses Whimscape's poppy unchanged because both flowers are red and a palette split made the stem brown. The existing Biomes O' Plenty models still control placement and petal count. The `potted_rose` model already references the rose block texture, so it gains the same treatment without another PNG or model override.

| Biomes O' Plenty block | Whimscape pattern | New PNGs |
| --- | --- | --- |
| `bush` | `bush` | `block/bush` |
| `dead_grass`, `desert_grass` | `short_dry_grass` | Both block textures |
| `dune_grass` | `tall_dry_grass` | `block/dune_grass` |
| `rose` and `potted_rose` | `poppy` | `block/rose` |
| `white_petals` | `pink_petals` | Block petal/stem and item textures |
| `wildflower` | `wildflowers` | Block flower/stem and item textures |

These are 11 new PNGs for seven directly adapted blockstates, one potted blockstate that shares the rose texture, and two item icons. [Plant comparison preview](Whimscape%20x%20Biomes%20o%20Plenty-plant-preview.png) shows each new PNG beside the installed mod's original.

Saplings are deliberately excluded. Whimscape sapling PNGs are texture atlases for custom 3D models, whereas Biomes O' Plenty saplings use flat cross models with separate potted and item assets. A simple PNG copy would show fragments. High grass, sprout, tundra shrub, violet, mushrooms, vines, and fantasy or organic blocks also differ in silhouette or model enough that a borrowed Whimscape pattern would look out of place. Keep those original until a deliberate in-game review supports a specific mapping.

## Whole-mod coverage

The installed Biomes O' Plenty `21.1.0.14` JAR has 429 blockstate IDs:

| Group | Blockstate IDs | Status |
| --- | ---: | --- |
| Wood construction blocks, including stripped logs and wood | 221 | Addressed by the wood textures and model overrides; visual QA remains. |
| Stone, mineral, and terrain blocks | 59 | Addressed by the second pass; visual QA remains. |
| Leaves and leaf piles | 25 | Addressed by the leaf pass; visual QA remains. |
| Closely matched plants | 7 | Addressed by the plant pass; visual QA remains. |
| Potted rose | 1 | Uses the new rose texture through the existing model; visual QA remains. |
| Saplings | 20 | Original Biomes O' Plenty style retained. |
| Other potted plants and saplings | 34 | Original style retained; some share textures with unpotted forms. |
| Other blocks | 62 | Original style retained. Includes flowers, grasses, crops, fungi, vines, cobwebs, fluids, and fantasy/organic blocks. |

The JAR also has 95 item PNGs. This pack overrides 65 wood-related PNGs, three maple leaf-pile icons, and two flower icons; 25 remain, including other plant items, buckets, rose quartz chunk, and a music disc. The item count overlaps the block groups above and is not an additional block count. The 116 remaining blockstates are intentionally left in their original style pending manual visual QA; a beta can ship with that boundary if it is acceptable in game.

### Deferred from the stone pass for manual QA

The five fantasy/organic candidates from the stone inventory remain in Biomes O' Plenty's original style: `null_block`, `flesh`, `porous_flesh`, `flesh_tendons`, and `flesh_tendons_strand`. `anomaly`, `wispjelly`, `spider_egg`, `glowshroom_block`, and `toadstool_block` were also identified as edge cases outside the stone/terrain scope. These are only a subset of the 116 blockstate IDs left in their original style. Review them in game before deciding whether they belong in a later pass.

## Rebuild

Run `powershell -NoProfile -ExecutionPolicy Bypass -File '.\Resource Pack\Generation\Build-Whimscape-BiomesOPlenty.ps1'` from the repository root. Inputs are `Resource Pack/Raw/Whimscape_1.20.2-1.21.11_r7.zip` and `Mods/Individual/Client-Server/BiomesOPlenty-fabric-1.21.1-21.1.0.14.jar`. The script refuses to overwrite its ZIP; remove or rename an older generated ZIP before rebuilding. When upgrading either input, check the wood names and texture paths again.

To include this add-on in a new SUCCU ZIP, run `Resource Pack/Generation/Build-ResourcePack.ps1` after rebuilding it. The SUCCU builder creates its own dated ZIP, UUID, and SHA-1 companions.

### Combined package built 2026-10-30

`Resource Pack/SUCCU_ResourcePack_26.10.30b.zip` includes this add-on in the `order.json` position immediately above the Whimscape base. Its companions are `SUCCU_ResourcePack_26.10.30b.uuid` (`e8e4a429-be34-4d1a-be3e-9fe9efe4ac28`) and `SUCCU_ResourcePack_26.10.30b.sha1` (`f0c43153c75df5479845ec38eb61356c633cd5c7`). The combined archive contains 24,742 merged asset files. All 731 add-on asset entries are present with identical content, the SHA-1 companion matches the ZIP, and the archive retains pack format 34 and Fusion metadata. This is archive verification, not an in-game test.

## Verification

The generated ZIP has 299 wood PNGs, 62 stone/terrain PNGs, 33 leaf/pile PNGs, and 11 plant PNGs, plus model and blockstate overrides and pack metadata. Archive inspection checked the 59 stone and 25 leaf/pile blockstates and found every referenced Biomes O' Plenty texture in the ZIP. The 11 plant PNGs exist at the mod's expected paths and dimensions. The 720 pre-plant ZIP entries other than `pack.mcmeta` remained byte-identical. The 732-entry archive has no duplicate or backslash paths. This verifies the asset package only.

In Minecraft, compare planks, logs, stripped logs, doors, fences, signs, and boats with Whimscape enabled. Pay special attention to the two nether-pattern woods (empyreal and magic), since their source stem art is animated in Whimscape but the Biomes O' Plenty logs are static. For stone, place black, white, and orange sandstone beside their sand, cut, chiseled, smooth, slab, stair, and wall variants. Also inspect brimstone's bud/cluster/fumarole, the five thermal calcite distance states and vent, rose quartz buds, null/algal End stone overlays, mossy black sand, and origin grass with and without snow. For leaves, compare all color families across biomes, check flowering oak and pine overlays, mossy willow, magic's alternate state, null leaves beside null End stone, and all three leaf-pile inventory icons. Compare the seven adapted plants, potted rose, and the white-petal and wildflower items against original Biomes O' Plenty plants nearby. Check both fast and fancy leaves and compare with shaders off and on. The ZIP has not been tested in a running client.
