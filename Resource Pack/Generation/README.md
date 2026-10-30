# Build the SUCCU resource pack

Run `powershell -ExecutionPolicy Bypass -File '.\Resource Pack\Generation\Build-ResourcePack.ps1'` from the repository root. The script reads every ZIP in `Resource Pack/Raw` and the exact filename order in `Resource Pack/Generation/order.json`, beside the script. Later entries have higher priority when two packs provide the same path. It refuses missing, duplicate, or unlisted ZIPs so newly added packs require an explicit order decision.

The output goes in `Resource Pack` as `SUCCU_ResourcePack_DD.MM.YY.zip` with a matching `.uuid` text file. Another run on the same day appends `a`, then `b`, through `z` directly after the date, for example `SUCCU_ResourcePack_29.10.26a.zip`. Each build gets a new version 4 UUID. Existing outputs are never overwritten. The input ZIPs are not modified.

For a Java Edition server resource pack, copy the UUID from the `.uuid` file into `resource-pack-id=` in `server.properties` when using that ZIP. The UUID is a server setting, not a field in `pack.mcmeta`. [Minecraft 1.20.3 Pre-Release 1 notes](https://feedback.minecraft.net/hc/en-us/articles/21502506063245-Minecraft-Java-Edition-1-20-3-Pre-Release-1)

The order file targets Minecraft 1.21.1, whose resource pack format is 34. This matches the version in the installed mod filenames. The script applies each input's matching version overlays in their declared order, then merges its effective `assets`, `data`, and Fusion override files. The combined `pack.mcmeta` declares format 34 and retains Whimscape's Fusion settings. Change `target_pack_format` only after checking the new Minecraft version and the input packs' support.

## Why this order

- Minecraft uses the upper pack when two resource packs contain the same path. The JSON lists the inverse order, low priority first, because the script writes later entries over earlier ones. [Minecraft Wiki: resource pack precedence](https://minecraft.wiki/w/Resource_pack)
- Whimscape is a broad visual base; its Cobblemon, Exploration, and Trinkets add-ons follow it. Vanilla Tweaks and small item packs are placed above the broad base as local preference. This is a chosen conflict policy, not a universal author requirement. [Whimscape x Cobblemon](https://modrinth.com/resourcepack/whimscape-x-cobblemon)
- Fresh Animations precedes its compatibility pack. The refreshed base packs precede their `-fa` variants, so the variants can replace shared files. Fresh Animations says extensions belong above it; Fresh Compats requires Fresh Animations. [Fresh Animations](https://modrinth.com/resourcepack/fresh-animations), [Fresh Compats](https://modrinth.com/resourcepack/fresh-compats)
- Better Cats precedes Fresh Better Cats. The Better Cats author recommends high priority to avoid texture conflicts; its Fresh adaptation is placed later to win where it overlaps. [Better Cats](https://modrinth.com/mod/better-cats)
- The Cobblemon packs and Vivillon pack are late because they make narrow changes. Their relative order is a local preference where no clear author rule was found.

This build is for local use. Some source pack licenses restrict redistribution of a merged ZIP; check each pack's terms before sharing it.
