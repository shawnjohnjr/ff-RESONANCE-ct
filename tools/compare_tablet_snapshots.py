#!/usr/bin/env python3
"""Compare read-only CE pickup exports; never accesses a running process."""
import argparse
from dataclasses import dataclass
from pathlib import Path


@dataclass
class Snapshot:
    build: int
    inventory: int
    pickups: dict


def load(path):
    lines = Path(path).read_text(encoding='utf-8-sig').splitlines()
    if not lines or lines[0] != 'FORMAT\tFFRS_TABLET_PICKUPS_V1' or lines[-1] != 'END\tOK':
        raise ValueError(f'{path}: incomplete or unsupported snapshot')
    build = inventory = None
    pickups = {}
    for line in lines[1:-1]:
        fields = line.split('\t')
        if fields[0] == 'BUILD' and len(fields) == 2 and build is None:
            build = int(fields[1])
        elif fields[0] == 'SHARD_INVENTORY' and len(fields) == 2 and inventory is None:
            inventory = int(fields[1])
        elif fields[0] == 'PICKUP' and len(fields) == 7:
            mid, item, uid, opened, trap, unlocked = map(int, fields[1:])
            key = (mid, uid)
            if key in pickups or any(v not in (0, 1) for v in (opened, trap, unlocked)):
                raise ValueError(f'{path}: duplicate pickup or invalid boolean')
            pickups[key] = (item, opened, trap, unlocked)
        else:
            raise ValueError(f'{path}: invalid record: {fields[0]}')
    if build is None or inventory is None or inventory < 0:
        raise ValueError(f'{path}: missing or invalid metadata')
    return Snapshot(build, inventory, pickups)


def compare(before, after):
    if before.build != after.build:
        raise ValueError('Builds differ; do not compare layouts across versions')
    changes = []
    for key in sorted(before.pickups.keys() | after.pickups.keys()):
        old, new = before.pickups.get(key), after.pickups.get(key)
        if old != new:
            changes.append((key, old, new))
    return after.inventory - before.inventory, changes


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('before')
    parser.add_argument('after')
    args = parser.parse_args()
    try:
        delta, changes = compare(load(args.before), load(args.after))
    except (OSError, ValueError) as exc:
        parser.exit(2, f'Error: {exc}\n')
    print(f'Shard inventory delta: {delta:+d} (inventory, not lifetime collection total)')
    for (mid, uid), old, new in changes:
        print(f'map={mid} unique_id={uid}: {old} -> {new}')
    print(f'{len(changes)} changed pickup records. Values: (definition_id, is_open, trap_disabled, is_unlocked).')
    print('A definition_id of -1 / 4294967295 does NOT by itself identify a Tablet Shard.')
    print('Confirm a shard using the loaded actor item ID 25004 and a controlled before/after pickup.')


if __name__ == '__main__':
    main()
