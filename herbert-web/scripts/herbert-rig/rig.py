import re,glob,math,json,sys
from PIL import Image
import numpy as np
guid={}
for m in glob.glob('**/*.meta',recursive=True):
    g=re.search(r'^guid: (\w+)',open(m,errors='ignore').read(),re.M)
    if g: guid[g.group(1)]=m[:-5]
t=open('Scenes/Herbert.prefab').read()
docs=re.split(r'^--- !u!(\d+) &(\d+)',t,flags=re.M)
objs={docs[i+1]:(docs[i],docs[i+2]) for i in range(1,len(docs),3)}
name={f:re.search(r'm_Name: (.*)',b).group(1) for f,(c,b) in objs.items() if c=='1'}
T={}
for f,(c,b) in objs.items():
    if c=='4':
        go=re.search(r'm_GameObject: \{fileID: (\d+)',b).group(1)
        def v(k):
            m=re.search(k+r': \{x: ([-\d.e]+), y: ([-\d.e]+), z: ([-\d.e]+)(?:, w: ([-\d.e]+))?',b); return [float(x) for x in m.groups() if x]
        q=v('m_LocalRotation'); z=2*math.atan2(q[2],q[3])
        T[f]=dict(go=go,pos=v('m_LocalPosition')[:2],rot=z,sc=v('m_LocalScale')[:2],father=re.search(r'm_Father: \{fileID: (\d+)',b).group(1))
def mat(t):
    c,s=math.cos(t['rot']),math.sin(t['rot'])
    return np.array([[c*t['sc'][0],-s*t['sc'][1],t['pos'][0]],[s*t['sc'][0],c*t['sc'][1],t['pos'][1]],[0,0,1]])
cache={}
def world(f):
    if f in cache: return cache[f]
    t=T[f]; m=mat(t)
    if t['father'] in T: m=world(t['father'])@m
    cache[f]=m; return m
go2t={v['go']:k for k,v in T.items()}
# sprite sheet rects for sliced sprites
def sheet_rects(path):
    s=open(path+'.meta').read(); out={}
    for m in re.finditer(r'- serializedVersion: 2\n\s+name: (.*)\n\s+rect:\n\s+serializedVersion: 2\n\s+x: ([\d.]+)\n\s+y: ([\d.]+)\n\s+width: ([\d.]+)\n\s+height: ([\d.]+)',s):
        out[m.group(1)]=tuple(float(x) for x in m.groups()[1:])
    ids=re.findall(r'internalID: (-?\d+)',s); names=list(out.keys())
    return {i:out[n] for i,n in zip(ids,names)} if len(ids)>=len(names) else {}
sprites=[]
for f,(c,b) in objs.items():
    if c!='212': continue
    go=re.search(r'm_GameObject: \{fileID: (\d+)',b).group(1)
    sp=re.search(r'm_Sprite: \{fileID: (-?\d+), guid: (\w+)',b)
    if not sp or sp.group(2) not in guid: continue
    path=guid[sp.group(2)]; so=int(re.search(r'm_SortingOrder: (-?\d+)',b).group(1))
    en=re.search(r'm_Enabled: (\d)',b).group(1)
    sprites.append(dict(go=go,name=name[go],path=path,fid=sp.group(1),order=so,enabled=en,doc=len(sprites)))
if __name__=='__main__':
    for s in sprites:
        W=world(go2t[s['go']]); 
        print(s['name'],s['path'].split('/')[-1],s['fid'],'order',s['order'],'en',s['enabled'],'world pos',W[:2,2].round(2),'rot',round(math.degrees(math.atan2(W[1,0],W[0,0])),1),'sc',round(float(np.hypot(W[0,0],W[1,0])),3))
