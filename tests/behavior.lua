local c={};for k,v in pairs(defaults) do c[k]=v end
local ch={id='chr_0027_tangtang',yaw=0}
local allowed,current,failInstall,failCleanup=true,nil,false,false
local count={capture=0,install=0,release=0,turn=0,pose=0,effects=0}
local P={pressed=function() return false end,character=function() return ch end,
    allowed=function() return allowed end,ownsCamera=function(l) return current==l end,
    capture=function(character) count.capture=count.capture+1;return {character=character,yaw=0,pitch=0} end,
    install=function(l) count.install=count.install+1;current=l;if failInstall then error('install failure') end end,
    release=function(l) count.release=count.release+1;l.releasing=true;if failCleanup then return false end;if current==l then current=nil end;return true end,
    bodyYaw=function(l) return l.character.yaw end,canTurn=function() return not blockTurn end,
    turn=function(l,yaw) l.character.yaw=yaw;count.turn=count.turn+1 end,
    pose=function(l,y,p,c,dt) count.pose=count.pose+1;lastPose={y=y,p=p,fov=c.fov} end,
    effects=function(l,e,c,dt) count.effects=count.effects+1;lastEffect=e end,
    id=function(l) return l.character.id end,report=function() count.report=(count.report or 0)+1 end}
local m=Factory(P);m.configure(c);m.frame(.016);assert(not m.lease)
m.toggle();m.frame(.016);assert(m.lease and count.install==1 and lastPose.fov==85)
m.look(44,0);m.frame(.016);assert(count.turn==0,'88 degrees does not turn')
m.look(2,0);m.frame(.016);assert(count.turn==1 and ch.yaw>0,'past 90 turns native body')
for i=1,90 do m.frame(1/60) end
assert(math.abs(m.angle(m.yaw-ch.yaw))<1 and not m.turning)
m.look(0,100);assert(m.pitch==-80);m.look(0,-100);assert(m.pitch==80)
assert(m.angle(359)==-1 and m.angle(-359)==1)
c.fov='110';m.configure(c);m.frame(.016);assert(lastPose.fov==110 and count.install==1,'hot apply no camera recreation')
c.fun_effects='true';m.configure(c);m.frame(.016);assert(lastEffect=='eyepatch')
for _,v in ipairs({{'chr_0002_endminm','scan'},{'chr_0003_endminf','scan'},{'chr_0018_dapan','sunglasses'},{'chr_0005_chen','none'}}) do
    ch.id=v[1];m.frame(.016);assert(lastEffect==v[2])
end
c.endmin_scan='false';m.configure(c);assert(m.effect('chr_0002_endminm')=='none')
c.fun_effects='false';m.configure(c);assert(m.effect('chr_0027_tangtang')=='none')
allowed=false;m.frame(.016);assert(not m.lease and not current and m.wanted,'UI/cinematic suspends but remembers choice')
allowed=true;m.frame(.016);assert(m.lease and count.install==2)
local previous=m.lease;ch={id='chr_0018_dapan',yaw=180};m.frame(.016);assert(m.lease~=previous and count.install==3,'character switch recaptures own proportions')
current='foreign';m.frame(.016);assert(m.lease and m.lease~=previous,'mock permits reinstall after foreign release')
current='foreign';allowed=false;m.frame(.016);assert(not m.lease and current=='foreign')
allowed=true;m.frame(.016);m.toggle();assert(not m.lease and not m.wanted)
m.toggle();failInstall=true
local ok,err=pcall(m.frame,.016);assert(not ok and m.lease,'partial lease retained before install failure')
m.fault(err);assert(not m.lease and m.failed and not m.wanted)
failInstall=false;m.toggle();m.frame(.016);assert(m.lease)
failCleanup=true;m.toggle();assert(m.lease and m.lease.releasing,'failed cleanup tracked')
m.frame(.016);assert(m.lease);failCleanup=false;m.frame(.016);assert(not m.lease)
m.toggle();m.frame(.016);c.enabled='false';m.configure(c);assert(not m.lease and not m.wanted)
local bad={};for k,v in pairs(c) do bad[k]=v end;bad.fov='nan';assert(not pcall(m.configure,bad));assert(m.settings.fov==110,'invalid config atomic')
print('PASS state machine: angle threshold/wrap, native turn, hot config, effects, suspensions, recapture, partial-failure cleanup')
for _,aspect in ipairs({4/3,16/9,21/9}) do
    assert(m.eyepatchAlpha(0,.5,aspect)==1 and m.eyepatchAlpha(1,.5,aspect)==0)
    local a=m.eyepatchAlpha(.4,.5,aspect);assert(a>0 and a<1)
    assert(m.eyepatchAlpha(.4,0,aspect)<a,'circular rather than vertical border')
    for x=0,100 do local v=m.eyepatchAlpha(x/100,.15,aspect);assert(v>=0 and v<=1) end
end
local cfg={};for k,v in pairs(defaults) do cfg[k]=v end
local body={id='test',yaw=0};local request,stops,requests,direct= nil,0,0,0
local port={};for k,v in pairs(P) do port[k]=v end
port.character=function()return body end
port.capture=function(ch)return {character=ch,yaw=ch.yaw,pitch=0} end
port.install=function(l)current=l end
port.turn=function(l,yaw,c,target)
    if c.native_body_turn then request=target;requests=requests+1;return not rejectNative end
    body.yaw=yaw;direct=direct+1;return true
end
port.stopTurn=function()if request then stops=stops+1;request=nil end end
local t=Factory(port);cfg.turn_threshold='30';t.configure(cfg);t.toggle();t.frame(.016)
t.look(15,0);t.frame(.016);assert(direct==0,'exact threshold does not trigger')
t.look(.5,0);t.frame(.016);assert(direct==1,'configurable low threshold')
for i=1,60 do t.frame(.016)end
cfg.turn_threshold='120';t.configure(cfg);t.yaw=t.angle(body.yaw+119);t.frame(.016)
assert(not t.turning);t.yaw=t.angle(body.yaw+121);t.frame(.016);assert(t.turning)
for i=1,60 do t.frame(.016)end
cfg.turn_threshold='180';t.configure(cfg);t.yaw=t.angle(body.yaw+180);local previous=direct;t.frame(.016)
assert(not t.turning and direct==previous,'180 disables automatic rotation')
cfg.turn_threshold='0';t.configure(cfg);t.yaw=t.angle(body.yaw+5);t.frame(.016);assert(direct>previous)
for i=1,60 do t.frame(.016)end
cfg.turn_threshold='30';cfg.native_body_turn='true';t.configure(cfg)
body.yaw=170;t.yaw=-159;t.frame(.016)
assert(request==-159 and requests==1 and t.turning and body.yaw==170,'native path wraps and waits for actual yaw')
body.yaw=-160;t.frame(.016);assert(not t.turning and not request and stops==1,'native completion reads actual body')
t.yaw=-100;t.frame(.016);assert(request==-100)
blockTurn=true;t.frame(.016);assert(not request and stops==2,'unsafe state cancels own turn');blockTurn=false
t.frame(.016);assert(request==-100,'can resume after native gate')
cfg.native_body_turn='false';t.configure(cfg);assert(not request and stops==3,'hot mode switch cancels native request')
t.frame(.016);assert(direct>previous)
for i=1,60 do t.frame(.016)end
cfg.native_body_turn='true';t.configure(cfg);t.yaw=t.angle(body.yaw+50);t.frame(.016)
t.toggle();assert(not t.lease,'lease release on disable')
for _,bad in ipairs({'-1','181','nan','not-a-number'}) do
    cfg.turn_threshold=bad;assert(not pcall(t.configure,cfg));assert(t.settings.turn_threshold==30,'invalid threshold remains atomic')
end
cfg.turn_threshold=nil;cfg.native_body_turn=nil;cfg.turn_in_place=nil;t.configure(cfg)
assert(t.settings.turn_threshold==90 and not t.settings.native_body_turn and t.settings.turn_in_place,'legacy config gets defaults')
cfg.native_body_turn='invalid';assert(not pcall(t.configure,cfg))
print('PASS configurable 0/30/120/180 thresholds, wrap, legacy defaults, native async completion, locks and hot mode switch')

cfg.native_body_turn='false';cfg.turn_in_place='invalid';assert(not pcall(t.configure,cfg));assert(t.settings.turn_in_place)

cfg.turn_in_place='true';cfg.head_look_binding=nil;t.configure(cfg);assert(not t.settings.head_look_binding)
cfg.head_look_binding='true';t.configure(cfg);assert(t.settings.head_look_binding)
cfg.head_look_binding='bad';assert(not pcall(t.configure,cfg));assert(t.settings.head_look_binding)
