# FINAL FANTASY RESONANCE — Cheat Engine Table

[繁體中文](README.md) | **English**

For Steam **build 24250053**. Tested on macOS with standard CrossOver and Windows Cheat Engine 7.7 x64.

## Features

| Entry | Function |
|---|---|
| 01 | Read-only check of current Gil and inventory record count |
| 02 | Set Gil: 0–9,999,999 |
| 03 | Read-only inventory list: internal item IDs and quantities |
| 04 | Select an owned item and change its quantity: 1–99 |
| 05 | Raise current party members to Lv.99 and recalculate their parameters through game functions |
| 06 | Endgame equipment pack: top up 8 weapons, 3 armor types, and 4 accessories |

Entries are independent and disabled by default. Changes are applied once, without freezing values. Unchecking an entry does not undo its changes. To run it again, uncheck and recheck it.

## Usage

1. Back up your save, enter a map, and remain in a menu. Do not battle, use items, shop, or change maps while an operation is running.
2. Run Windows CE in the same CrossOver bottle as the game and load the [CT](FFRS_Steam_24250053_Starter.CT).
3. Enable entry 01 and compare its values with the game menu. The first object scan takes time; avoid repeated clicks.
4. Select a feature. The item editor presents a list first, then asks for a quantity. Canceling makes no change.
5. Close and reopen the game menu to verify the result, then save to a new slot.

The CT connects to `FFRS-Win64-Shipping.exe`, checks the executable version, and locates the active save through the current world. It stops on an unsupported build; compatibility with other updates is not guaranteed.

### Item picker

The picker reads the game's data tables and lists owned consumables and equipment with **English / Traditional Chinese names, IDs, and quantities**. Names come from the installed build 24250053's official `en` and `zh-Hant` localization, matched by item ID. It includes 507 name pairs; all 505 consumable and equipment rows loaded during testing had matching labels. Two official Traditional Chinese fields still contained Japanese, so they use explicitly marked provisional Chinese translations. Unknown IDs display “Unknown item / 未翻譯道具” with their IDs preserved.

Examples: `Potion / 治療劑`, `Phoenix Down / 鳳凰尾巴`, and `Crimson Saber / 深紅烈焰`. Key items, Artifact items, and unowned items are excluded from this picker.

The 1–99 range is a conservative tool limit, not a claim about every item's maximum stack size. This editor does not create items or remove inventory records. It stops if the inventory address, record count, or selected quantity changes during input.

### Endgame equipment pack

Entry 06 calls the game's `AddInventory` function to bring inventory quantities up to **at least one of each weapon** and **at least eight of each armor and accessory listed below**. It preserves higher existing quantities and does not keep adding duplicates. It only adds inventory; it does not equip items, unlock characters, or change levels.

| Character | Weapon | ID |
|---|---|---:|
| Rain | Ragnarok+ | 10197 |
| Lasswell | Sasuke’s Blade+ | 10297 |
| Fina | Artemis Bow+ | 10397 |
| Lid | Thor’s Hammer+ | 10496 |
| Nichol | Last Resort+ | 10597 |
| Dark Fina | Fire Birch+ | 10696 |
| Jake | Arcturus+ | 10797 |
| Sakura | Wizard’s Rod+ | 10897 |

All eight weapons include the game's 99,999 damage-cap effect. Weapon types were checked against the eight characters' equipment compatibility. Effects remain subject to the game's battle rules.

- Armor: Tatenashi Armor+ (11397), Mirage Vest+ (11097), Lordly Robes+ (11597).
- Accessories: Super Ribbon (12101), Ultima Reactor (12095), Genji Gloves (12096), Omega Badge (12103).

This is a general endgame selection based on stats, effects, and equipment compatibility. Specialized builds may suit particular battles better. Three armor categories are provided so each character can choose a compatible type.

The script validates all equipment IDs and categories before granting items, then reads back each result. It stops if the inventory changes during execution. A failure midway can leave earlier grants applied; there is no automatic rollback, so inspect the inventory before retrying.

### Lv.99

This affects only main characters currently in the party. It does not unlock characters who have not joined or modify visions. It sums each character's level table to determine the EXP needed for Lv.99, checks that threshold with the game's level calculation, then calls `SetPlayableUnitExperience` to update saved EXP and live character parameters.

No battle is needed for the change to take effect. **Current HP and MP are not automatically refilled**; maximum HP/MP and other parameters are recalculated. Characters already at the target EXP are not rewritten. If execution fails midway, inspect the character state: this is not an atomic operation across the party, and completed updates are not automatically undone.

## CrossOver: missing VC++ x64 message at launch

### What caused it in this test

With standard CrossOver 26.3 and Steam build 24250053, the launcher displayed:

```text
The following component(s) are required to run this program:
Microsoft Visual C++ 2015-2022 Redistributable (x64)
```

The bottle already had the Microsoft VC++ runtime installed, but the DLL versions selected during launch did not satisfy the launcher. These are the observed versions for this environment, not universal values for all CrossOver releases:

| Check | Version |
|---|---|
| Minimum required by this game's launcher | 14.42.34438 |
| CrossOver's built-in `msvcp140_2.dll` and `vcruntime140_1.dll` | 14.42.34433.0 |
| Installed native Microsoft runtime DLLs in the bottle | 14.51.36247.0 |

An installed-runtime entry alone was therefore insufficient: DLL selection also mattered. Prioritizing the installed native Microsoft DLLs allowed the game to proceed to shader compilation and then a playable map.

### Launch procedure that worked

1. Exit Steam and the game normally in other CrossOver versions. Open and sign in to Steam through **standard CrossOver**, using the bottle containing the game.
2. Make sure that same bottle has a compatible **x64** Microsoft Visual C++ v14 Redistributable. If it is missing, obtain the x64 installer from [Microsoft's official download page](https://learn.microsoft.com/en-us/cpp/windows/latest-supported-vc-redist?view=msvc-170) and run it in that bottle through CrossOver. Match the package to the Windows game's x64 architecture.
3. With the game stopped, run the following in macOS Terminal. Adjust the first three variables to your installation. If CrossOver is in the system Applications directory, change the first line to `CROSSOVER_APP="/Applications/CrossOver.app"`.

```sh
CROSSOVER_APP="$HOME/Applications/CrossOver.app"
BOTTLE_NAME="Steam"
GAME_EXE='C:\Program Files (x86)\Steam\steamapps\common\FINAL FANTASY RESONANCE\FFRS.exe'

SteamAppId=3259780 SteamGameId=3259780 \
  "$CROSSOVER_APP/Contents/SharedSupport/CrossOver/bin/wine" \
  --bottle "$BOTTLE_NAME" --no-update \
  --dll 'msvcp140,msvcp140_1,msvcp140_2,vcruntime140,vcruntime140_1=n,b' \
  --debugmsg '-all' \
  --cx-app "$GAME_EXE"
```

`n,b` tries native Microsoft DLLs first, then CrossOver/Wine's built-in implementations. It does not install missing runtime files. `--no-update` avoids triggering a bottle update for this launch. The command explicitly selects standard CrossOver's executable.

This DLL selection applies only to this launch and child processes that inherit it. It does not write permanent bottle DLL overrides. A later launch using Steam's Play button may not inherit it; use the command again when needed. The successful test did not require reinstalling the game or changing CrossOver MGVF settings.

If standard CrossOver and MGVF share a bottle, installing or repairing runtime components still changes that shared Windows environment. In this case the appropriate native runtime was already present; the per-launch DLL selection was the key fix. These steps document the tested build. After game or CrossOver updates, recheck versions and the actual cause of any launch error.

### Follow-up fix: use the original CrossOver game icon

The Terminal command above fixes one launch at a time. The same arguments were subsequently saved in CrossOver's **shared FINAL FANTASY RESONANCE shortcut**, so launching from that icon no longer requires typing a command, opening a separate macOS launcher, or running Cheat Engine.

The original icon pointed to a Windows `.url` containing `steam://rungameid/3259780`, rather than directly executing `FFRS.exe`. When Steam is already running, environment variables supplied to a URL shortcut cannot be relied on to reach that existing Steam process. Although the GUI's Run Command dialog has an environment-variable field, the final fix used CrossOver's bundled `cxmenu` tool to replace the original icon's actual launch command.

What was changed:

1. Back up the bottle's `cxmenu.conf` and `cxbottle.conf`, plus both original Resonance `.url` files in the Windows Desktop and Start Menu folders.
2. Move those two original files to a backup directory outside the shortcut scanner's search locations. This prevents a Windows shortcut rescan from replacing the custom commands with Steam URL launches. Keep the originals for rollback.
3. Use `bin/cxmenu --bottle … --create … --type raw --command … --icon … --description … --install` from the standard CrossOver installation to update the **two existing Resonance entries** in `cxmenu.conf`, preserving their display name and icon. Here, `--create` targeted existing entry identifiers; it did not create a differently named game icon.
4. Pin the command to standard CrossOver's `bin/wine`, launch `FFRS.exe` directly, and include the same `SteamAppId`, `SteamGameId`, `--no-update`, and `--dll …=n,b` arguments shown above. Avoid a program path that changes with the currently selected CrossOver version.
5. Compare settings before and after: only the two Resonance menu entries changed, `cxbottle.conf` remained byte-for-byte identical, and other game shortcuts—including Ninja Gaiden 4—were unchanged. With the game closed, launch from its original CrossOver icon. The user confirmed reaching the title screen without the VC++ error.

**Shared scope:** Standard CrossOver and MGVF share the Steam bottle and menu configuration on this machine. Both therefore see the same Resonance shortcut. With the user's approval, only that game's shortcut was changed to launch through standard CrossOver. The MGVF application, graphics options, bottle-wide DLL overrides, and other game settings were not changed. This shared-shortcut fix should not be described as affecting only one GUI.

**Everyday use:** Open and sign in to the bottle's Steam using standard CrossOver, then click **FINAL FANTASY RESONANCE** in CrossOver. This does not add launch arguments to the Play button in Steam's library. Recheck the stored command after moving CrossOver or the game, recreating shortcuts, or an update that changes the configuration.

**Rollback:** Restore both original `.url` files to their original locations, restore the corresponding two entries in `cxmenu.conf`, then re-export/refresh the menus with CrossOver's menu tool. If other shortcuts have changed meanwhile, do not overwrite the entire configuration with an old copy. Machine-specific paths and backups are not included in this public repository.

## Validation status — October 26, 2026

- All six Lua entries passed CE syntax checks.
- Bilingual picker: all 505 live data-table rows passed name/ID/category matching. Labels and quantity prompts for the nine initially owned supported items were checked; cancellation left the inventory unchanged.
- Gil: changed from 600 to 1,000,000 and read back successfully.
- Items: the actual entry 04 script changed Potion from 13 to 14 and back to 13. The entire inventory matched its original bytes afterward.
- Item cancellation, invalid quantities, stale inventory, and stale quantity checks passed without altering the inventory.
- Entry 05: Rain and Lasswell changed from 0 to 15,848,325 EXP. The game's calculation and live character fields returned Lv.99, and the user confirmed both menu levels.
- Live character parameters updated. Repeating the Lv.99 operation left saved character bytes unchanged.
- Equipment pack: 64 pieces across 15 equipment IDs were added and read back correctly. Existing inventory quantities, Gil, and character data stayed unchanged. Cancellation made no change; repeating the operation added zero pieces and preserved inventory bytes. All new equipment appeared in the bilingual picker data.
- **The in-game item/new-equipment display and persistence after saving and reloading have not been verified.** Item tests supplied choices and input values to the actual CT scripts; manual interaction with the selection dialog has not been claimed as tested.

## Source layout

- `src/game_connection.lua`: executable checks, active-save lookup, and data-table discovery.
- `src/item_names.lua`: English/Traditional Chinese item labels and categories; names only, without descriptions or dialogue.
- `src/unreal_tables.lua`: table lookup, sparse row iteration, and validation.
- `src/inventory_items.lua`: owned-item choices, quantity writes, and inventory-change checks.
- `src/party_progression.lua`: character-array validation, party lookup, and Lv.99 EXP planning.
- `src/memory_checks.lua`: native-function byte-signature checks.
- `src/party_upgrade.lua`: level-function validation, character updates, and read-back verification.
- `src/inspect_save.lua`: read-only save inspection.
- `src/set_gil.lua`: Gil input and update.
- `src/list_inventory.lua`: inventory IDs and quantities.
- `src/edit_item_quantity.lua`: bilingual picker and quantity-edit flow.
- `src/upgrade_party_to_level_99.lua`: current-party Lv.99 action.
- `src/grant_endgame_equipment.lua`: endgame equipment top-up action.
- `build.py`: standalone CT generation.

`TABLE_ENTRIES` in `build.py` explicitly defines each entry's stable ID, title, source, and helper requirement. Dependencies are not inferred from numbered filenames or list positions. Display order can change; preserve existing IDs.

`GAMEPLAY_HELPER_SOURCES` defines helper assembly order. Inventory operations depend on tables and labels; upgrades depend on progression planning and memory checks. Lua files are concatenated into one lexical scope, preserving local functions without requiring a separate module loader. Existing advanced entries still include the full helper bundle to keep the previously tested CT content identical.

Place new shared functions in the appropriate file. Register new helper files in `GAMEPLAY_HELPER_SOURCES` before callers that depend on them. Helper files should end with a newline. Missing source files stop generation before the CT is written.

To add an action, create a descriptively named Lua file in `src/` and register a unique ID and source path in `TABLE_ENTRIES`. Keep shared lookup and data operations in helpers; action files handle the user interaction and operation flow. The builder rejects duplicate IDs, duplicate action sources, and missing source files.

Edit Lua sources and regenerate the CT rather than editing the generated file directly. For source-only reorganizations, compare the generated CT's SHA-256 before and after. For execution-logic changes, perform CE syntax checks and the relevant live tests.

Build with Python 3:

```sh
python3 build.py
```

The repository does not include game files, personal saves, memory dumps, or local test logs, and the CT does not change CrossOver settings. The CT has no startup autorun Lua; actions execute only when enabled manually.

See [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) for data-layout references and licensing. This is an unofficial tool and is not affiliated with Square Enix.
