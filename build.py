from pathlib import Path
import xml.etree.ElementTree as E
ROOT=Path(__file__).resolve().parent
common=(ROOT/'src/common.lua').read_text(encoding='utf-8')
helpers=(ROOT/'src/editors.lua').read_text(encoding='utf-8')
labels=['01 唯讀檢查：目前 Gil 與背包筆數','02 設定持有 Gil','03 唯讀背包清單：內部 ID 與數量','04 選擇道具並修改數量（日文名稱／已持有）','05 目前隊伍升至 Lv.99']
root=E.Element('CheatTable',CheatEngineTableVersion='45')
entries=E.SubElement(root,'CheatEntries')
for i,label in enumerate(labels,1):
 e=E.SubElement(entries,'CheatEntry')
 E.SubElement(e,'ID').text=str(i)
 E.SubElement(e,'Description').text='"'+label+'"'
 E.SubElement(e,'VariableType').text='Auto Assembler Script'
 body=(ROOT/f'src/entry{i}.lua').read_text(encoding='utf-8')
 E.SubElement(e,'AssemblerScript').text='[ENABLE]\n{$lua}\nif syntaxcheck then return end\n'+common+'\n'+(helpers if i>=4 else '')+'\n'+body+'\n{$asm}\n[DISABLE]\n'
E.SubElement(root,'UserdefinedSymbols')
E.indent(root)
E.ElementTree(root).write(ROOT/'FFRS_Steam_24250053_Starter.CT',encoding='utf-8',xml_declaration=True)
