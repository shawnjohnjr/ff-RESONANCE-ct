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
| 06 | Endgame equipment pack: top up 8 weapons, 5 armor types, and 8 accessories |
| 07 | Automatic basic Attack: runs while checked; uncheck to stop |
| 08 | Automatically confirm battle results: standalone or together with entry 07 |
| 09 | Upgrade owned visions: maximum awakening/current-party MR, one vision or all owned |
| 10 | Acquire one missing vision or all 26; skip owned visions |
| 11 | Fill the current acting character’s Limit gauge once; no automatic casting |
| 12 | Unlock Fel Meteor for Dark Fina once; skip if already learned |
| 13 | One-shot map walking/running/jogging speed: 1x, 1.5x, 2x, 3x |

Entries are independent and disabled by default. Entries 01–06 run once, without freezing values; unchecking does not undo changes. Uncheck and recheck to run them again. Entries 07 and 08 run while checked and can be disabled separately. Their shared callback is removed when both are disabled.

Entry 09 performs a one-time upgrade in batches. Turn off 07/08 first, make the selections, then keep the game foreground until completion. Unchecking stops remaining operations without undoing completed upgrades.

## Usage

1. Back up your save. For entries 01–06, enter a map and remain in a menu; do not battle, use items, shop, or change maps during the operation. For entries 07 and 08, follow the battle automation instructions below.
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

The following equipment from the [Twelve Arms / arena rewards guide](https://forum.gamer.com.tw/C.php?bsn=179&snA=92417&tnum=1) is also included, with a minimum of 8 each. IDs and categories are checked against the game's equipment table.

| English / Traditional Chinese name | ID | Category |
|---|---:|---|
| Lorica Sancta / 神聖甲 (Japanese: ホーリーメイル) | 11033 | Light armor |
| Lorica Apocalyptica / 終焉之鎧 | 11329 | Heavy armor |
| Gold Hairpin+ / 黃金頭飾·改 | 12097 | Accessory |
| Thunder God’s Earrings / 雷帝的耳環 | 12080 | Accessory |
| Ribbon / 緞帶 | 12065 | Accessory |

Also includes **Circlet of Enlightenment / 解脫之輪 (12069)**, topped up to at least 8 in inventory. It adds 5% Limit gauge per turn and is used in the Nichol build below. Owning 1 adds 7; owning 8 or more adds nothing.

Ribbon and Super Ribbon remain separate items. The Shinryu reward mentioned in the guide is excluded from this equipment pack. Names use the game's English and Traditional Chinese localization rather than literal translations from Japanese.

This is a general endgame selection based on stats, effects, and equipment compatibility. Specialized builds may suit particular battles better. Three armor categories are provided so each character can choose a compatible type.

The script validates all equipment IDs and categories before granting items, then reads back each result. It stops if the inventory changes during execution. A failure midway can leave earlier grants applied; there is no automatic rollback, so inspect the inventory before retrying.

### Lv.99

This affects only main characters currently in the party. It does not unlock characters who have not joined or modify visions. It sums each character's level table to determine the EXP needed for Lv.99, checks that threshold with the game's level calculation, then calls `SetPlayableUnitExperience` to update saved EXP and live character parameters.

No battle is needed for the change to take effect. **Current HP and MP are not automatically refilled**; maximum HP/MP and other parameters are recalculated. Characters already at the target EXP are not rewritten. If execution fails midway, inspect the character state: this is not an atomic operation across the party, and completed updates are not automatically undone.

### Upgrade owned visions

Entry 09 selects one owned vision or all owned visions, then maximum awakening, maximum current-party MR, or both. Labels use the official English/Traditional Chinese names; unknown names retain their IDs.

Turn off entries 07/08 and remain at the vision menu on a map. After accepting the prompt, return focus to the game and avoid changing maps, party members or vision growth until the completion message. The operation stops after two minutes. Reopen the vision menu to verify, then save to a new slot.

- Only owned visions are upgraded. No visions are unlocked. MR applies only to current party members; other characters retain their points.
- Limits come from the game's `GetMaxMasteryPoint`/`GetMaxLevel`. Awakening and per-character mastery are separate; MRP requirements are not assumed identical across visions. Already-maxed entries are skipped.
- Uses native `SetAwakeningMasteryPoint`/`SetSynchroMasteryPoint` and verifies each point value and level. No magicite or Gil is consumed.
- Validates world, save, ownership, party, object lifetimes and original points. Battles or mismatched data reject the operation. Calls run on the game-window thread and are sent only while the game is foreground.
- This is not an atomic batch. Cancellation, focus loss or an error can leave earlier upgrades completed; inspect the game before saving or retrying. Canceling a selection dialog makes no changes.

Live validation (2026-10-26): Leah awakening was tested first, then formal entry 09 completed 11 upgrades: the other two awakenings and three party members × three visions for MR. The user confirmed Tronn, Leah and Warrior of Light at 3 stars and current-party MR maxed; native getters returned MR 9. Owned IDs, non-party points, inventory and Gil were unchanged. Canceling either selection dialog also preserved the data. Persistence after saving and restarting the game has not been separately tested.

### Acquire visions

Entry 10 acquires one missing vision or fills out all 26 supported visions, including Sephiroth. The picker uses official English/Traditional Chinese labels. Owned visions are skipped and retain their awakening and per-character MR. New visions start with normal default growth; entry 09 can upgrade them separately.

Back up your save, turn off 07/08, wait for 09 to finish, and remain in a field menu. Select the scope, enter `YES`, then keep the game foreground until completion. Reopen the vision menu and save to a new slot. Unchecking stops remaining grants without undoing completed ones.

- Calls the supported build's native acquisition routine on the game window thread. The game allocates the vision array and initializes MRP records for all eight playable characters; the CT does not fabricate these containers.
- Validates the game's Vision DataTable against 26 known IDs, the build, function signatures, world, save, battle state and object lifetimes. Each grant is checked for owned count, unchanged existing growth, eight initial MRP records, Gil and inventory.
- The native routine updates collection achievements and **may immediately unlock Steam achievements**. Unchecking or loading an older save does not undo those achievements.
- Does not complete shrine questions, quests or associated boss events. Later acquisition through every original story event has not been fully tested. Correct menus and saves do not establish compatibility with the entire story.

Live validation (2026-10-26, standard CrossOver): Amelia was acquired first and the user confirmed viewing/equipping her worked. Formal entry 10 then added the remaining 21, reaching 26. Per-grant checks passed; the original four visions' growth, Gil and inventory were preserved. The user confirmed the full roster displayed correctly and Steam collection achievements appeared. Both cancellation paths and repeating the action with all visions owned passed without additional grants. The user saved to a new slot, reloaded it in-game, and confirmed all 26 visions remained with the vision menu working normally.

### Automatic basic Attack

Entry 07 adapts the MIT-licensed [Resonance Game Boosters](https://github.com/Darjjj/resonance-game-boosters). It uses the game's existing action selection, command eligibility checks, and target selection functions to make the current friendly character use basic Attack. It does not restore the disabled native AutoBattle feature or use magic/items. Entry 07 alone does not automatically dismiss battle results. If basic Attack is unavailable, it waits.

- Keep Windows Cheat Engine open and entry 07 checked. Enable it again after each game launch. It does not persist in saves or install an ASI/DLL mod.
- Battle automation now uses direct subsystem/widget links and class reflection. Fresh discovery in the tested standard CrossOver session took about 13.5 seconds in a read-only probe; the formal CT selected its first attack after about 15.2 seconds. These are observations, not timing guarantees. Enabling the second feature while the other is running reuses the existing connection. Keep the game in the foreground at an ordinary battle's command selection screen.
- No commands are sent when Windows/Wine reports another foreground window, the game is paused, or a cinematic is playing. Focus reporting for every macOS window-switching scenario is not guaranteed; uncheck the entry to explicitly pause automation.
- Unchecking stops new commands; an already confirmed attack may finish its animation. If stopped during target selection, cancel or complete that command manually before enabling again.
- Polling stops when the game exits or CE attaches to another process. Closing CE stops new requests; an in-flight request is not guaranteed to be canceled.

A game-window message callback invokes `ProcessEvent` on the game's own thread without overwriting existing game/engine code. Calls have a deadline and validate the current world, registry slots, serial numbers, and command state; changed state rejects the call. Disabling removes the hook. Small allocations remain until game exit to avoid freeing callback code while an invocation could still be returning.

**Earlier crash and fix:** An unpublished prototype crashed when its callback read control data, before sending an attack. The dump identifies that failed access but does not establish why the data became unreadable. The revised dispatcher separates read/write control data from callback code and uses `VirtualQuery` to validate the control region and each guard address before reading. In an isolated test, deliberately making control data inaccessible was safely skipped; calls resumed after restoring access. Invalid addresses and mismatched state also rejected execution. This does not claim to establish an underlying CrossOver or Rosetta cause.

- When direct links are unavailable, fallback discovery temporarily increases to at most 4,096 objects per slice when a valid battle command state has no matching view, using both a reverse scan from the registry tail and the forward sweep, then returns to 256 once found. Initial discovery uses at most 2,048. Every 32 objects it checks a 20 ms time budget; these are scan limits, not guaranteed completion times.
- Every two seconds, stale view and function caches are pruned; class and inheritance cleanup visits at most 8 entries per cache per pass. Cached objects/classes are checked by address and lifetime identity so reused locations do not inherit stale entries. Disabling both automation modes clears the caches. Faster discovery mainly adds reads and CPU work; actual memory usage has not been measured.

At `SELECT RESONANCE`, entry 07 cancels the selection and resumes ordinary attacks without choosing a finisher. Cancellation requires Finish command mode, the matching battle phase, a visible command view, and the existing foreground/scene guards. It addresses that view’s cancellation function, never a global key.

**Direct discovery:** `GWorld → World subsystem map → CPP_UI_BattleSubsystem → BtlWidget (validated weak index/serial) → WBP_BattleLayout_C → WBP_BtlCmdLayout_C → VM_BtlCmd` locates the command view. The same subsystem exposes `ResultWidget`; the game-instance subsystem map exposes the overall UI root. Result widgets can be created only after victory: their `InputDecide` function is resolved from their class when they appear. Native functions are resolved through class child lists, avoiding a full function-object sweep. Successful direct discovery stops the registry sweep; missing links retain the original fallback. All existing call-time state, identity, foreground and scene guards remain in place.

Entries 07/08 use a lightweight read-only connection without scanning inventory tables. Entries 01–06 retain their full save/table connection. Each launch reacquires live pointers; no process addresses or registry indices are saved between launches. First startup still requires native class discovery, so it is not instantaneous. The live tests below cover this Steam build on standard CrossOver, not every scene or machine.

Live validation (2026-10-26): after restarting the game and CE, the formal CT started with an empty battle cache and completed two consecutive ordinary battles with entries 07/08 enabled. The user confirmed return to the map in both; the second battle required no reload or toggle. Logs recorded 9 confirmed attacks, 2 resonance cancellations and 14 result-page confirmations, with no runtime errors. Isolated tests cover invalid direct links, world changes, class-function discovery and flags, reused registry slots, bounded cleanup, scan budgets, resonance cancellation conditions and result guards.

### Automatically confirm battle results

Entry 08 is an independent switch: battle manually and let the CT handle results, or enable both 07 and 08 to automate basic attacks through result completion. Disabling 08 preserves auto-attack; disabling 07 preserves automatic results.

Adapted from [Resonance Game Boosters](https://github.com/Darjjj/resonance-game-boosters), this feature calls only the current result widget's `InputDecide`, sending confirm/release events at least 250 ms apart. It does not send global Enter/key input. The game handles animations, count-ups, page transitions, and normal reward processing; reward values are not directly modified.

Before sending, it validates the result widget, current page, result model, and viewport root. Active system/modal widgets, pausing, or cinematic playback block confirmation. Confirmation stops when results finish or gameplay resumes. If confirmation retires the widget, release is not redirected to another screen. CE must remain open, and Windows/Wine must report the game as foreground.

Both entries share one game-thread callback. Disabling both stops polling and removes that callback. A confirmation already dispatched may complete; unchecking cannot undo normal battle rewards already collected. Ordinary battle results were tested; special story battles, defeat/retry flows, and every reward-page variant have not been exhaustively tested.

### Refill the current acting character's Limit gauge

Entry 11 fills the friendly character currently awaiting a normal battle command to their live Limit-gauge cap once. Disable 07/08, wait for the intended character's turn, enable 11, then return to the game and keep it foreground. Choose a Limit Burst manually afterward. Uncheck and recheck to refill again. Unchecking cancels a pending refill but does not undo one already completed.

This fills the gauge only: it does not unlock skills, cast automatically, or freeze the value. Resonance selection, target selection, enemies, pause, and cinematics are excluded. It stops after two minutes without an eligible screen. The game-thread dispatcher and lifetime checks are reused; the native setter receives the battle ID from the character parameter, not the command view's unique ID. The result is read back against the character's live cap; this build's global maximum is 200 (two bars).

Live test (2026-10-27, standard CrossOver): the formal script changed the acting character's gauge from 65 to 200, verified by readback and the user's visual confirmation. Dark Fina was also refilled from 0 to 200; the user confirmed that her Limit Burst executed normally with its animation. It does not issue a save command; the game's own autosaves can still persist gameplay state.

## Build reference: Nichol's opening support sequence

Based on [Yuzu GameLab's Nichol equipment and vision guide](https://www.youtube.com/watch?v=nMJ8TWN3NO0). The sequence below was read from the battle footage, with skill names and effects checked against this build's Traditional Chinese data. This is a manual-play reference, not a new CT feature. The video's million-damage result has not been reproduced in this project's live tests.

The shown build uses Last Resort+, Circlet of Enlightenment, Gold Hairpin+, and Amelia. Equipped abilities include Terra MASTER, Firion MASTER, the starting Limit-gauge passive, the passive that charges the gauge after a non-damaging action, triple Limit-gauge gain, and the first-action passive. Nichol must personally acquire the relevant vision mastery abilities; owning the visions or accessories alone is insufficient. Chinese skill labels below match the footage and avoid inventing official English names.

| Step | Action | Purpose |
|---|---|---|
| 1 | Use W臂腕 | Queue two commands in one action |
| 2 | First command: 轉戰自如之策, targeting Nichol himself | Enables another action after a formation skill; this effect can trigger only once per turn |
| 3 | Second command: 攻勢之陣 | Raises the party's break damage and triggers the extra action |
| 4 | Use W臂腕 again | Queue the second pair of commands |
| 5 | First command: Limit skill 鏡面晶寫之術 | Gives the party a one-use effect that executes the selected action twice |
| 6 | Second command: 突擊之陣 | Raises the party's critical-hit rate before the attackers act |

Video references: [first pair at approximately 2:55–3:14](https://www.youtube.com/watch?v=nMJ8TWN3NO0&t=175s), [second pair at approximately 3:19–3:49](https://www.youtube.com/watch?v=nMJ8TWN3NO0&t=199s). Apply 轉戰自如之策 to Nichol before using 攻勢之陣. Combined with starting gauge, non-damaging-action charging, and triple gauge gain, the footage shows enough gauge for the Limit skill after the first pair. Circlet of Enlightenment also supplies 5% Limit gauge per turn. The title's “zero-turn” wording does not mean unconditional or unlimited actions.

**Entry 07 performs only basic attacks; it does not execute this sequence.** Disable entry 07 when following the build manually. This section covers Nichol's opening only; subsequent teammate commands, enemy mechanics, and final damage require their own setup.

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

- Auto results: the prototype and actual entry 08 returned to the map. With 08 disabled, results stayed open with zero confirmations. Entry 08 alone completed results; 07 and 08 together completed an ordinary battle automatically. The user confirmed normal character/item menus were not accidentally operated.
- Switching features preserved the same shared callback; disabling one retained the other, and disabling both cleared the dispatcher enable flag. Result-flow tests cover no result page, pause, rejected calls, paired confirm/release, rate limiting, return to gameplay, and no release to a retired widget.

- Lua enable/disable blocks for all eight entries compiled in CE 7.7; the original six scripts and descriptions remain byte-for-byte unchanged.
- Auto Attack: the user confirmed the single-action prototype. The actual entry 07 then selected and confirmed 3 attacks across two battles; the user confirmed normal visuals and resumed attacks after returning to the foreground. The first result screen waited for manual confirmation. Unchecking cleared the dispatcher enable flag and stopped the counters; after re-enabling and exiting the game normally, polling stopped without a callback error.
- Isolated dispatcher tests: 100 revised calls passed; 20 window messages safely skipped intentionally inaccessible control data, and calls resumed after access was restored. Mismatched state and unreadable guard addresses rejected calls. The underlying reason the original control data became inaccessible has not been established.
- Bilingual picker: all 505 live data-table rows passed name/ID/category matching. Labels and quantity prompts for the nine initially owned supported items were checked; cancellation left the inventory unchanged.
- Gil: changed from 600 to 1,000,000 and read back successfully.
- Items: the actual entry 04 script changed Potion from 13 to 14 and back to 13. The entire inventory matched its original bytes afterward.
- Item cancellation, invalid quantities, stale inventory, and stale quantity checks passed without altering the inventory.
- Entry 05: Rain and Lasswell changed from 0 to 15,848,325 EXP. The game's calculation and live character fields returned Lv.99, and the user confirmed both menu levels.
- Live character parameters updated. Repeating the Lv.99 operation left saved character bytes unchanged.
- Equipment pack: 64 pieces across 15 equipment IDs were added and read back correctly. Existing inventory quantities, Gil, and character data stayed unchanged. Cancellation made no change; repeating the operation added zero pieces and preserved inventory bytes. All new equipment appeared in the bilingual picker data.
- Expanded pack live test: added 8 each of Lorica Sancta, Lorica Apocalyptica, Gold Hairpin+, Thunder God’s Earrings, and Ribbon (40 pieces). All five categories and bilingual picker labels matched. Gil, character data, and other inventory quantities were unchanged. Cancellation wrote nothing; repeating added zero pieces and preserved inventory bytes. The user also confirmed that all five items display correctly in the game menu.
- **The in-game item/new-equipment display and persistence after saving and reloading have not been verified.** Item tests supplied choices and input values to the actual CT scripts; manual interaction with the selection dialog has not been claimed as tested.

## Source layout

- `src/game_thread_dispatch.lua`: game-window thread calls with memory checks and deadlines.
- `src/vision_names.lua`, `vision_progression.lua`, `vision_upgrade.lua`: vision labels, owned data/upgrade planning and native execution; `upgrade_owned_visions.lua` handles dialogs.
- `tests/vision_progression_test.lua`: selection scope, current-party restriction, per-vision limits, no-op repeats and invalid data.
- `src/battle_direct_links.lua`: validated subsystem maps, weak battle-widget links, and direct command/result/root lookup.
- `src/battle_objects.lua`: battle object/function discovery and command context validation.
- `src/battle_calls.lua`: shared native/Blueprint function validation and guarded calls.
- `src/battle_actions.lua`: basic Attack and target selection flow.
- `src/result_actions.lua`: result/page/modal validation and confirmation flow.
- `src/battle_runtime.lua`: shared dispatcher and polling lifecycle for independent switches.
- `src/enable_auto_attack.lua` / `src/disable_auto_attack.lua`: auto-attack switch.
- `src/enable_auto_results.lua` / `src/disable_auto_results.lua`: auto-results switch.
- `tests/battle_direct_links_test.lua`: invalid weak serial, wrong class/owner, map bounds and world-change tests.
- `tests/result_actions_test.lua`: result-event safety tests without the game; run with Lua 5.3+ from the repository root.

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

`VISION_HELPER_SOURCES` defines vision helper assembly separately from continuous battle polling. Extend the corresponding vision modules without growing the inventory or character-level modules.

Entry 10 modules: `src/vision_acquisition.lua` handles the catalog, missing roster, native acquisition and readback; `src/acquire_visions.lua` handles dialogs; `tests/vision_acquisition_test.lua` covers repeats, growth preservation and invalid data.

### Dark Fina: Fel Meteor

Entry 12 reuses the live-tested native learning and parameter-refresh calls to add Fel Meteor (408160) to Dark Fina, preserving existing skills and EXP. Disable 07/08, leave battle, stay in a normal menu, enable the entry, and return to the game foreground. Already-learned skills are skipped. Unchecking cancels a pending action; it does not remove a learned skill.

Skill display, battle execution, and animation were confirmed in-game. Use entry 11 separately to refill the Limit gauge.

### Magitek Armor Key / 魔導裝甲之鑰

Entry 04 now includes **Magitek Armor Key / 魔導裝甲之鑰 (29500)**. Selecting it grants one if missing and skips if already owned. Stay outside battle in a normal menu, then return the game to the foreground; unchecking cancels a pending grant. Ordinary item quantity editing still requires ownership, and other key items remain excluded.

After acquiring a chocobo, use the key in the game’s Items menu to switch its appearance. Tested on standard CrossOver on 2026-10-27: quantity 0 → 1, other inventory and Gil unchanged; the user confirmed successful use and magitek armor riding appearance.

### Map movement speed

Use entry 13 while on foot with free map control. Choose 1.5x, 2x or 3x relative to the recorded baseline, without compounding; choose 1x to restore it. Stop and resume movement to refresh the movement component. Unchecking does not restore speed; re-enable and select 1x to restore.

This is a one-shot change to the current map actor, with no freeze or global time scaling. Map changes, battles or restarting may reset it; rerun as needed. Mounted use is unsupported. Map transitions, interiors, mounts and battle transitions have not been live-tested. On 2026-10-27, the user confirmed faster overworld movement at 1.5x; 2x and 3x passed readback, and the user accepted 3x for publication. Baselines were walking 180, running 450 and jogging 230; overworld movement used jogging. Only those three speeds are changed, not animation or battle time scaling.

The formal implementation also passed live readback for 3x → baseline (180/450/230) → 3x (540/1350/690).
