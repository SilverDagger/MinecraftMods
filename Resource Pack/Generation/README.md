# Build the SUCCU resource pack

Run `powershell -ExecutionPolicy Bypass -File '.\Resource Pack\Generation\Build-ResourcePack.ps1'` from the repository root. The script reads every ZIP in `Resource Pack/Raw` and the exact filename order in `Resource Pack/Generation/order.json`, beside the script. Later entries have higher priority when two packs provide the same path. It refuses missing, duplicate, or unlisted ZIPs so newly added packs require an explicit order decision.

The output goes in `Resource Pack` as `SUCCU_ResourcePack_YY.MM.DD.zip` with matching `.uuid` and `.sha1` text files. Another run on the same day appends `a`, then `b`, through `z` directly after the date, for example `SUCCU_ResourcePack_26.10.29a.zip`. Each build gets a new version 4 UUID and the SHA-1 of the finished ZIP. Existing outputs are never overwritten. The input ZIPs are not modified.

For a Java Edition server resource pack, copy the UUID from the `.uuid` file into `resource-pack-id=` and the 40-character lowercase digest from `.sha1` into `resource-pack-sha1=` in `server.properties` when using that ZIP. These values describe the ZIP served to players; changing the ZIP requires a new SHA-1. [Minecraft 1.20.3 Pre-Release 1 notes](https://feedback.minecraft.net/hc/en-us/articles/21502506063245-Minecraft-Java-Edition-1-20-3-Pre-Release-1), [server properties reference](https://minecraft.wiki/w/Server.properties)

The order file targets Minecraft 1.21.1, whose resource pack format is 34. This matches the version in the installed mod filenames. The script applies each input's matching version overlays in their declared order, then merges its effective `assets`, `data`, and Fusion override files. The combined `pack.mcmeta` declares format 34 and retains Whimscape's Fusion settings. Change `target_pack_format` only after checking the new Minecraft version and the input packs' support.

## Why this order

- Minecraft uses the upper pack when two resource packs contain the same path. The JSON lists the inverse order, low priority first, because the script writes later entries over earlier ones. [Minecraft Wiki: resource pack precedence](https://minecraft.wiki/w/Resource_pack)
- Whimscape is the visual base; its Cobblemon, Exploration, and Trinkets add-ons follow it. Vanilla Tweaks is below Whimscape because its randomized grass and dirt blockstates conflict with Whimscape's textures. Vanilla Tweaks paths that Whimscape does not replace remain available. Small item packs follow the broad base as a local preference. [Whimscape x Cobblemon](https://modrinth.com/resourcepack/whimscape-x-cobblemon)
- Fresh Animations precedes its compatibility pack. The refreshed base packs precede their `-fa` variants, so the variants can replace shared files. Fresh Animations says extensions belong above it; Fresh Compats requires Fresh Animations. [Fresh Animations](https://modrinth.com/resourcepack/fresh-animations), [Fresh Compats](https://modrinth.com/resourcepack/fresh-compats)
- Better Cats precedes Fresh Better Cats. The Better Cats author recommends high priority to avoid texture conflicts; its Fresh adaptation is placed later to win where it overlaps. [Better Cats](https://modrinth.com/mod/better-cats)
- The Cobblemon packs and Vivillon pack are late because they make narrow changes. Their relative order is a local preference where no clear author rule was found.
- The trimmed Maxi's JourneyMap Cobblemon Minimap Icons U11 ZIP supplies 2,945 `assets/cobblemon/textures/entity_icon` PNGs. The original U11 ZIP was replaced with this local variant, which crops transparent borders from the icons. U11 targets Minecraft 1.21.1; the author's [U11 release notes](https://modrinth.com/resourcepack/maxis-journeymap-cobblemon-icons/version/U11?dep=1) say it was tested with JourneyMap 6.0.0 beta 56. In JourneyMap, set Mob Display to Icons for the minimap preset and fullscreen map to see the icons. `Trim-EntityIcons.ps1` is the helper used on an extracted `Maxi's-JM+CM_Pixel-U11` folder beside the script; it does not run during the combined-pack build.
- E19 was removed from the inputs. It supplies Xaero's Minimap icons plus Cobblemon textures and models, while this mod set has JourneyMap and no Xaero minimap. E19 and Maxi have no overlapping asset paths, so E19 was adding roughly 10,000 unrelated merged files rather than improving Maxi's JourneyMap icons. The source ZIP is recoverable from Git history if Xaero is added later.

This build is for local use. Some source pack licenses restrict redistribution of a merged ZIP; check each pack's terms before sharing it.

## In-game checks

Test in a copied world with only the newly built SUCCU pack enabled. Reload resources with F3+T, then place a flat patch and a small hole of grass, dirt, and coarse dirt in one biome. Compare it with Whimscape alone and Vanilla Tweaks alone, keeping shaders off for the first comparison. Walk around the patch and reload resources again; the Whimscape grass blockstate intentionally has a few random variants, but grass should no longer use Vanilla Tweaks' separate variated models. Then test snow-covered grass, dirt paths, glass connections, mobs, Cobblemon, books, armor, and the interface. Add any other resource packs and shaders back one at a time. If the problem appears only with a shader, inspect its settings separately from the ZIP merge.

## Minecart and selected hotbar item fixes (Minecraft 1.21.1)

The 2026-10-29 screenshots showed a distorted minecart inventory icon and an item hidden in the selected hotbar slot. The builder now makes two targeted corrections for pack format 34:

- Whimscape's `format_18-42` overlay supplies 3D models for the six vanilla minecart items. The build omits those six item model JSON files, so Minecraft uses its built-in flat item models with Whimscape's `assets/minecraft/textures/item/*minecart.png` textures. This is a conservative visual workaround for the reported minecart appearance; the source packs and placed minecart entity textures are unchanged.
- Cobblemon Interface is later than Whimscape and replaces `assets/minecraft/textures/gui/sprites/hud/hotbar_selection.png`. Its 24×23 selection PNG has an opaque center (544 opaque pixels, only 8 transparent), while Whimscape's center is transparent. The build explicitly takes Whimscape's selection sprite after merging, retaining the rest of Cobblemon Interface's GUI.

The corrected local build is `SUCCU_ResourcePack_26.10.29b.zip`, with matching `.uuid` and `.sha1` files. To test it, enable only that ZIP, reload with F3+T, select several hotbar slots, and compare a regular and chest minecart in the inventory. The ZIP contents were checked, but the result has not been verified in a running client. If the server serves the ZIP, update its `resource-pack-id` and `resource-pack-sha1` to match the new sidecar files before testing the server copy.

The subsequent `SUCCU_ResourcePack_26.10.29c.zip` includes Maxi's U11 icons and retains these two fixes. Use its own `.uuid` and `.sha1` sidecars if serving that version.

## October 30 build and boat inventory icons

`SUCCU_ResourcePack_26.10.30.zip` uses the trimmed Maxi icon ZIP and the same `-UseVanillaTextShaders` option as variant d. It also omits Whimscape's format 34 inventory models for the nine wooden boat/chest boat pairs and the bamboo raft/chest raft pair. Minecraft 1.21.1 can then use its built-in flat item models. The merged pack retains the entity boat textures and other Whimscape assets. This targets the black/magenta boat icons reported in chest inventories; verify the result in game after reloading resources with F3+T. The ZIP was checked locally, but no client test has been performed.

The current ZIP's UUID is in `SUCCU_ResourcePack_26.10.30.uuid`; its SHA-1 is in `SUCCU_ResourcePack_26.10.30.sha1`. The older `SUCCU_ResourcePack_24.4.27.zip` now has its own matching `.uuid` and `.sha1` companions. Use the sidecars that match the exact ZIP served to players. Generated and source ZIPs are tracked through Git LFS; `.sha1` and `.uuid` remain ordinary Git text files.

## October 30a item icon correction

`SUCCU_ResourcePack_26.10.30a.zip` uses only Maxi for JourneyMap/Cobblemon icons and retains the `-UseVanillaTextShaders` comparison option. The earlier build omitted vanilla chest boat item models, but those icons were still black/magenta in inventory. The builder now writes explicit flat `item/generated` models for all nine wooden chest boats and the bamboo chest raft, each pointing to its existing `textures/item` icon. It also replaces Vanilla Tweaks' 3D item models for the 12 vanilla sign and hanging sign materials with flat icon models. Wall signs use the same sign item icon. Placed sign and boat entity textures remain in the pack.

The ZIP, `.uuid`, and `.sha1` files share the `SUCCU_ResourcePack_26.10.30a` basename. Their archive structure, model JSON, and texture references were checked locally. Test the icons in a chest or inventory with only this ZIP enabled and reload resources with F3+T; in-game rendering is still unverified.

## October 30 custom boat icon correction

`SUCCU_ResourcePack_26.10.30.zip` also replaces Cobblemon's apricorn and saccharine boat and chest boat item models with flat generated models using their existing item icons. Their placed-boat entity textures are unchanged. The four model references and PNG paths were checked locally; in-game rendering is still unverified.

## Floating nameplate comparison build

If floating player and Pokémon names become black rectangles only while an Iris shader pack is active, use `SUCCU_ResourcePack_26.10.29d.zip` as a comparison build. It differs from `...29c.zip` only by omitting Cobblemon Interface's `assets/minecraft/shaders/core/rendertype_text.fsh` and `rendertype_text_intensity.fsh`, allowing Minecraft's built-in text shaders to load. Build another comparison ZIP with `powershell -ExecutionPolicy Bypass -File '.\Resource Pack\Generation\Build-ResourcePack.ps1' -UseVanillaTextShaders`. The normal build retains the original source shaders.

With the same shader pack, settings, client, and world, enable only `...29d.zip` and compare player and Pokémon names to `...29c.zip`. If the blackout disappears, the custom text shader is involved and this comparison build can serve as a workaround. If it remains, inspect the active shader pack and Iris version; the resource pack change did not address the cause. The comparison ZIP has not been tested in a running client. Its server `resource-pack-id` and `resource-pack-sha1` must use the `...29d` sidecars if served from a server.
