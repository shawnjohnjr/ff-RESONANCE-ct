"""Build the standalone CT from named Lua actions without executing game code."""

from dataclasses import dataclass
from pathlib import Path
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parent
SOURCE_DIR = ROOT / "src"
OUTPUT_FILE = ROOT / "FFRS_Steam_24250053_Starter.CT"


@dataclass(frozen=True)
class TableEntry:
    entry_id: int
    title: str
    source: str
    uses_gameplay_helpers: bool = False


# IDs are stable; list order controls display order only.
TABLE_ENTRIES = (
    TableEntry(1, "01 唯讀檢查：目前 Gil 與背包筆數", "inspect_save.lua"),
    TableEntry(2, "02 設定持有 Gil", "set_gil.lua"),
    TableEntry(3, "03 唯讀背包清單：內部 ID 與數量", "list_inventory.lua"),
    TableEntry(
        4, "04 選擇道具並修改數量（英文／繁中／已持有）",
        "edit_item_quantity.lua", uses_gameplay_helpers=True,
    ),
    TableEntry(
        5, "05 目前隊伍升至 Lv.99",
        "upgrade_party_to_level_99.lua", uses_gameplay_helpers=True,
    ),
    TableEntry(
        6, "06 全角色終盤裝備包（補足背包）",
        "grant_endgame_equipment.lua", uses_gameplay_helpers=True,
    ),
)


def validate_entries(entries):
    """Catch configuration mistakes before writing the output file."""
    seen_ids = set()
    seen_sources = set()
    for entry in entries:
        if entry.entry_id <= 0 or entry.entry_id in seen_ids:
            raise ValueError(f"Invalid or duplicate entry ID: {entry.entry_id}")
        if entry.source in seen_sources:
            raise ValueError(f"Duplicate entry source: {entry.source}")
        seen_ids.add(entry.entry_id)
        seen_sources.add(entry.source)
        if not (SOURCE_DIR / entry.source).is_file():
            raise FileNotFoundError(SOURCE_DIR / entry.source)


def read_source(filename):
    return (SOURCE_DIR / filename).read_text(encoding="utf-8")


def assemble_script(entry, connection, gameplay_helpers):
    """Keep the emitted script layout stable for byte-for-byte verification."""
    helpers = gameplay_helpers if entry.uses_gameplay_helpers else ""
    action = read_source(entry.source)
    return (
        "[ENABLE]\n{$lua}\nif syntaxcheck then return end\n"
        + connection + "\n" + helpers + "\n" + action
        + "\n{$asm}\n[DISABLE]\n"
    )


def build_table():
    validate_entries(TABLE_ENTRIES)
    connection = read_source("game_connection.lua")
    gameplay_helpers = (
        read_source("item_names.lua") + "\n" + read_source("gameplay_helpers.lua")
    )

    root = ET.Element("CheatTable", CheatEngineTableVersion="45")
    entries = ET.SubElement(root, "CheatEntries")
    for entry in TABLE_ENTRIES:
        node = ET.SubElement(entries, "CheatEntry")
        ET.SubElement(node, "ID").text = str(entry.entry_id)
        ET.SubElement(node, "Description").text = f'"{entry.title}"'
        ET.SubElement(node, "VariableType").text = "Auto Assembler Script"
        ET.SubElement(node, "AssemblerScript").text = assemble_script(
            entry, connection, gameplay_helpers
        )

    ET.SubElement(root, "UserdefinedSymbols")
    ET.indent(root)
    return ET.ElementTree(root)


def main():
    table = build_table()
    table.write(OUTPUT_FILE, encoding="utf-8", xml_declaration=True)
    print(f"Built {OUTPUT_FILE.name} ({len(TABLE_ENTRIES)} entries)")


if __name__ == "__main__":
    main()
