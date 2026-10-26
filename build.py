"""Build the standalone CT from named Lua actions without executing game code."""

from dataclasses import dataclass
from pathlib import Path
from typing import Optional
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parent
SOURCE_DIR = ROOT / "src"
OUTPUT_FILE = ROOT / "FFRS_Steam_24250053_Starter.CT"


# Lua helpers share one lexical scope in the generated CT.
# Keep dependencies before their callers; concatenate without adding separators
# so splitting source files does not alter the already-tested scripts.
GAMEPLAY_HELPER_SOURCES = (
    "unreal_tables.lua",      # tableRows, findTable
    "inventory_items.lua",    # inventoryChoices, setItem
    "party_progression.lua",  # arrayAt, partyPlan
    "memory_checks.lua",      # checkCode
    "party_upgrade.lua",      # checkLevelFunctions, setParty99
)


BATTLE_HELPER_SOURCES = (
    "game_thread_dispatch.lua", "battle_direct_links.lua", "battle_objects.lua", "battle_calls.lua",
    "battle_actions.lua", "result_actions.lua", "battle_runtime.lua",
)


VISION_HELPER_SOURCES = (
    "game_thread_dispatch.lua", "battle_direct_links.lua", "battle_objects.lua", "battle_calls.lua",
    "vision_names.lua", "vision_progression.lua", "vision_upgrade.lua",
)


VISION_ACQUISITION_HELPER_SOURCES = (
    "game_thread_dispatch.lua", "battle_direct_links.lua", "battle_objects.lua",
    "unreal_tables.lua", "memory_checks.lua", "vision_names.lua",
    "vision_progression.lua", "vision_acquisition.lua",
)

@dataclass(frozen=True)
class TableEntry:
    entry_id: int
    title: str
    source: str
    uses_gameplay_helpers: bool = False
    helper_sources: tuple[str, ...] = ()
    disable_source: Optional[str] = None


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
    TableEntry(
        7, "07 自動普通攻擊（勾選啟用／取消停止）",
        "enable_auto_attack.lua",
        helper_sources=BATTLE_HELPER_SOURCES,
        disable_source="disable_auto_attack.lua",
    ),
    TableEntry(
        8, "08 自動確認戰後結算（獨立開關）",
        "enable_auto_results.lua", helper_sources=BATTLE_HELPER_SOURCES,
        disable_source="disable_auto_results.lua",
    ),
    TableEntry(
        9, "09 強化已持有幻兵（覺醒／目前隊伍 MR）",
        "upgrade_owned_visions.lua", helper_sources=VISION_HELPER_SOURCES,
        disable_source="disable_vision_upgrade.lua",
    ),
    TableEntry(
        10, "10 取得幻兵（單隻／補齊全部）",
        "acquire_visions.lua", helper_sources=VISION_ACQUISITION_HELPER_SOURCES,
        disable_source="disable_vision_acquisition.lua",
    ),
    TableEntry(
        11, "11 目前行動角色極限技槽補滿（一次）",
        "refill_limit_gauge.lua",
        helper_sources=("game_thread_dispatch.lua", "battle_direct_links.lua", "battle_objects.lua", "battle_calls.lua", "memory_checks.lua"),
        disable_source="disable_limit_refill.lua",
    ),
    TableEntry(
        12, "12 魔人菲娜解鎖地獄隕石（一次）",
        "unlock_fel_meteor.lua",
        helper_sources=("game_thread_dispatch.lua", "battle_direct_links.lua", "battle_objects.lua", "memory_checks.lua"),
        disable_source="disable_fel_meteor.lua",
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
        sources = (entry.source, *entry.helper_sources)
        if entry.disable_source:
            sources += (entry.disable_source,)
        for source in sources:
            if not (SOURCE_DIR / source).is_file():
                raise FileNotFoundError(SOURCE_DIR / source)


def read_source(filename):
    return (SOURCE_DIR / filename).read_text(encoding="utf-8")


def assemble_script(entry, connection, gameplay_helpers):
    """Keep the emitted script layout stable for byte-for-byte verification."""
    helpers = gameplay_helpers if entry.uses_gameplay_helpers else ""
    helpers += "".join(read_source(source) + "\n" for source in entry.helper_sources)
    action = read_source(entry.source)
    disable = ""
    if entry.disable_source:
        disable = ("{$lua}\nif syntaxcheck then return end\n"
                   + read_source(entry.disable_source) + "\n{$asm}\n")
    return (
        "[ENABLE]\n{$lua}\nif syntaxcheck then return end\n"
        + connection + "\n" + helpers + "\n" + action
        + "\n{$asm}\n[DISABLE]\n" + disable
    )


def build_table():
    validate_entries(TABLE_ENTRIES)
    connection = read_source("game_connection.lua")
    gameplay_helpers = (
        read_source("item_names.lua") + "\n"
        + "".join(read_source(source) for source in GAMEPLAY_HELPER_SOURCES)
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
