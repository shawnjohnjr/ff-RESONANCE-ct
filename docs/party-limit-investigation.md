# Party Limit refill: refresh/rollback investigation

Steam build 24250053 only. Runtime addresses below are module-relative (RVA).
Entry 15 now passes the live turn-transition, consumption and next-battle tests.

## Why a successful readback was misleading

`CPP_BtlUnitParameter + 0x118` is the current Limit value; `+0x2A0` is its cap.
Setting the current field to the cap makes the HUD show full. However, after an
ordinary attack, another game routine restores all actors' resource values from
an independent list. Thus an immediate readback is insufficient validation.

Observed on 2026-10-28: four characters were filled to 200, then the native setter
was called with 50, 185, 50, 0. The original setter wrote those values over 200.
This was captured by a temporary diagnostic that preserved the native write.
The diagnostic patches were removed after the capture.

## Confirmed native call chain

- `0x4F5CDED` calls `0x4F61240(owner, 0)`.
- Restore routine `0x4F61240` indexes `owner + 0x48` as an array whose count is at
  `+0x50`. Each outer entry is 0x30 bytes.
- Each outer entry contains a resource-row array at `+0x08`, count at `+0x10`.
- Each row is 0x14 bytes: actor unique ID at `+0x00`, HP at `+0x04`, MP at `+0x08`,
  Limit at `+0x0C`, and an additional resource at `+0x10` (meaning not yet verified).
- `0x4F61308` reads the row ID; `0x4F6130D` looks up its battle actor.
- `0x4F61375` loads the row's Limit value and `0x4F61378` calls
  `0x524AE80(parameter, points, false)`. Return address: `0x4F6137D`.

The owner was identified as `CPP_BtlDelEventCmd`, reached through the current
battle manager's delegate event array. The implementation checks object identity,
container pointers/counts and the battle actor unique ID before writing. Do not
search for matching integers and write them.

## Approaches that did not solve it

1. `SetBattleUnitLimitBurstPoint` at `0x4F617D0`: current value and UI update only.
2. Debug fill-all's gain path at `0x5230430`, followed by the battle UI notification
   at `0x4F4B7B0`: also rolled back. The gain path additionally updates `+0x284`
   and applies gain multipliers, so it is not an exact setter.
3. `parameter + 0x568` is a copy of the base parameter block used by another game
   path. It is **not established as the source of the observed Limit rollback**.
   Do not synchronize it just because a value happens to match.

## External references (read, not executed)

- [Katzy CT v1.14](https://opencheattables.com/viewtopic.php?p=6130): its infinite
  Limit feature hooks five query/write sites (RVAs 0x524AEB8, 0x4F55167,
  0x52305DE, 0x5238211, 0x523C7F0). It refills repeatedly, including consumption;
  this does not implement once-per-battle semantics. No code copied into entry 15.
- [Resonance Game Boosters](https://github.com/Darjjj/resonance-game-boosters):
  `src/limit_burst.hpp` repeatedly calls `SetBattleUnitLimitBurstPoint`.

## Required regression checks

1. Fill all living party members, including their unlocked extra bars; no popup.
2. Ordinary attack then advance to another actor: unused gauges remain full.
3. Spend a Limit: gauge is consumed normally, not immediately refilled.
4. Enter another battle without retoggling: all eligible gauges fill again.
5. Disable the feature and exit the game without leaving diagnostic code patches.

## Implemented fix and live results

`party_limit_snapshot.lua` discovers the command owner through the current world
and battle manager. It selects the single command snapshot, validates its row by
battle unique ID, and updates only its Limit field. The normal Limit setter runs
in the same guarded game-thread call. HP, MP and other row fields are not written.

User-confirmed in standard CrossOver: gauges survive an ordinary-attack turn
change, spending a Limit consumes the gauge without an immediate refill, and the
next battle refills the party without toggling. No completion popup. Tested caps
were 200; caps above 200 and game-exit behavior for entry 15 remain unverified.

See [version migration](version-migration.md) before adapting this to another build.
