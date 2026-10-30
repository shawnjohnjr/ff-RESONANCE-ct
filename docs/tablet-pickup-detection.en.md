# Read-only Tablet Shard pickup detection

[繁體中文：完整研究與位移表](tablet-pickup-detection.md)

Validated on Steam **build 24250053**, Windows Cheat Engine 7.7 x64 under macOS CrossOver. This is a reproducible research method, **not a complete 99-shard tracker**.

## Controlled observation

A player stopped before collecting the golden pickup at the west end of the Grandshelt Colosseum entrance path. The loaded actor was `BP_MapGimmick_FieldItem_Medal_C`, with item ID **25004**, quantity **1**, UniqueID **2**, and `m_IsOpen = 0`.

Read-only snapshots before and after normal pickup showed:

- Pickup key: `(mapId = 2016, UniqueID = 2)`.
- Record ID: `0xFFFFFFFF` (-1); unchanged.
- `IsOpen`: **0 → 1**.
- `IsUnlock`: **0 → 1**.
- `isDisableTrap`: **0 → 0**.
- Shard inventory: **+1**.
- No event-flag changes in the recorded comparison.

The important finding is that this shard uses the shared pickup/chest save records. Searching only story flags or chest item-definition tables did not identify it. This does not prove that no other shard ever affects an event flag.

## Layout

The active `CPP_MuchaSaveDataManager` owns its game save at `+0x60`. The save's `Map` is at `+0x1A8`, and `Map.mapGimmick` at `+0x70` (save `+0x218`). This is a sparse `TMap<int32, FSaveData_MapGimmick>` with element stride `0x110`, map key at `+0`, and value at `+8`.

The value begins with a `TArray<FSaveData_TreasureBox>`. Each entry is `0x0C` bytes: `ID +0`, `UniqueID +4`, `IsOpen +8`, `isDisableTrap +9`, `IsUnlock +0xA`. Respect sparse allocation bits when enumerating the map.

Actor fields: `m_UniqueId +0x328`, `m_ItemId +0x3F8`, `m_ItemNum +0x3FC`, and FieldItem `m_IsOpen +0x410`. These offsets are build-specific. The probe checks the executable timestamp `0x6A586B2F` and image size `503013376`, then validates the name pool, world, active save class, array bounds, booleans, and duplicate pickup keys.

The save's current-map field retained a prior parent-area ID during this experiment. Identify a pickup through its actual changed map record and actor package, not that field alone.

## Reproduce

Download the repository. In CE's Lua Engine, replace these with your own absolute Windows paths (or CrossOver mapped paths):

```lua
probe = dofile([[C:\research\ff-RESONANCE-ct\tools\tablet_probe.lua]])
probe.snapshot([[C:\research\before.tsv]])
-- Wait for completion. Collect exactly one known shard normally in the game.
probe.snapshot([[C:\research\after.tsv]])
```

Stay on the same map; do not load another save, collect other items, or deliver shards between snapshots. Use different output filenames; existing files are overwritten. Initial object discovery may take time. Loading the module alone does not scan. Snapshotting performs memory reads and explicit local TSV output only: no timers, injected calls, save edits, or game-memory writes.

Compare using Python 3:

```sh
python3 tools/compare_tablet_snapshots.py BEFORE_PATH AFTER_PATH
```

On macOS, use the native macOS paths to the TSV files. The comparison rejects incomplete snapshots, duplicate keys, and mismatched builds. The local files contain pickup progress; do not publish personal full exports.

## Limits

- `ID == -1` **does not identify a shard**: ordinary field pickups can share it.
- Confirm the actor's item ID 25004, then map it to its map/UniqueID record. [The verified catalog](../data/verified-tablets.json) currently contains **one** entry.
- A region with all recorded field pickups unopened and a count matching a location guide is a **candidate inference**, not an individually validated shard list.
- An absent record or unloaded actor is **unknown**, not evidence of collected/uncollected status. Unvisited maps, story variants, registration timing, and incomplete actor coverage matter.
- Inventory count is not lifetime collection count; delivering shards can lower it.
- A complete tracker needs all 99 actor-to-record mappings and validation across map variants, save files, and fresh launches.

## Validation

The original probe was used for the controlled live pickup above. The packaged standalone exporter separately passed Lua 5.4 fake-memory checks for inline/heap sparse allocation, unused slots, invalid booleans, and save-object changes. The Python comparator passed five tests. These checks are not a fresh live validation of the packaged tool on a second save.

```sh
python3 tests/tablet_snapshot_test.py
lua tests/tablet_probe_test.lua
```

## Sources

SDK layouts: [PolarWizard/final-fantasy-resonance-fix](https://github.com/PolarWizard/final-fantasy-resonance-fix), MIT; see [third-party notices](../THIRD_PARTY_NOTICES.md). Physical test location: [PowerPyx's shard guide, entry 58](https://www.powerpyx.com/final-fantasy-resonance-all-tablet-shard-locations/). The guide supplies location directions, not memory offsets.
