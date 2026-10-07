import sys
from pathlib import Path
sys.path.insert(0,sys.argv[1])
from lupa.lua54 import LuaRuntime
lua=LuaRuntime();compile=lua.eval('function(s) local f,e=load(s);assert(f,e) end')
for p in Path(sys.argv[2]).glob('*.lua'):compile(p.read_text(encoding='utf8'));print('PASS actual DLL transformed syntax:',p.name)
