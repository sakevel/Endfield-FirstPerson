import sys,argparse,configparser
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('--lupa-dir',required=True);a=p.parse_args();sys.path.insert(0,a.lupa_dir)
from lupa.lua54 import LuaRuntime
root=Path(__file__).resolve().parents[1];lua=LuaRuntime()
c=configparser.ConfigParser();c.read(root/'mod/config.ini',encoding='utf8')
lua.globals().config=lua.table_from({k[6:]:v['default'] for k,v in c.items() if k.startswith('field.')})
lua.execute((root/'tests/native_mock.lua').read_text(encoding='utf8'))
lua.globals().ZMLFPFactory=lua.execute((root/'mod/controller.lua').read_text(encoding='utf8'))
lua.globals().FP=lua.execute((root/'mod/native.lua').read_text(encoding='utf8'))
lua.execute((root/'tests/native_scenarios.lua').read_text(encoding='utf8'))
