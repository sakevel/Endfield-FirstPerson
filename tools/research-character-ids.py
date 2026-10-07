"""Confirm public character template IDs against byte-verified current VFS indices."""
import argparse,json,hashlib
from pathlib import Path
from research_vfs import extract
p=argparse.ArgumentParser();p.add_argument('--indices',type=Path,required=True);a=p.parse_args()
root=Path(__file__).resolve().parents[1];out=root/'artifacts/research'
records=json.loads((out/'current/inventory.json').read_text())
proof=[]
for name in ('bundles/windows/manifest.hgmmap','extenddata/main/stringpathhash.bin'):
    current=out/'character-indices'/Path(name).name;extract(records['data/'+name],current)
    assert current.read_bytes()==(a.indices/name).read_bytes(),'Client indices changed; reconvert them before using cached JSON'
    proof.append({'index':name,'sha256':hashlib.sha256(current.read_bytes()).hexdigest(),'byteExact':True})
manifest=json.loads((a.indices/'bundles/windows/manifest.json').read_text(encoding='utf8'))
ids=['chr_0027_tangtang','chr_0018_dapan','chr_0002_endminm','chr_0003_endminf']
entries=[]
for id in ids:
    paths=[x['path'] for x in manifest['Assets'] if '/postmodels/characters/' in x['path'] and x['path'].endswith('/'+id+'_postmodel.prefab')]
    assert len(paths)==1,(id,paths);entries.append({'id':id,'postmodel':paths[0]})
(out/'character-id-provenance.json').write_text(json.dumps({'indices':proof,'characters':entries,'readOnly':True},indent=2))
print('Verified current postmodel template IDs:',', '.join(ids))
