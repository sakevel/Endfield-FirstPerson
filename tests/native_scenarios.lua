local ctrl={}
FP.show(ctrl);assert(not FP.lease and registrations==1)
pressToggle=true;runGroup('Tick',1/60);runGroup('TailTick',1/60)
assert(FP.lease and FP.lease.manager.curActiveController==baseLevel and FP.lease.overrideId)
local l=FP.lease
approximate(l.camera.transform.position.y,1.68);approximate(l.camera.fieldOfView,85)
assert(render1.shadowCastingMode==1 and render2.shadowCastingMode==3,'body visible, only head renderer hidden')
approximate(head.localScale.x,.001)
-- Restore before gameplay/animation; apply only again in the render tail.
runGroup('Tick',.016);approximate(head.localScale.x,1)
runGroup('TailTick',.016);approximate(head.localScale.x,.001)
change('fov','100');runGroup('Tick',1/60);runGroup('TailTick',1/60);assert(l.camera.fieldOfView==100 and FP.lease==l)
change('smoothing','0');change('height_variation','false')
head.position=CS.UnityEngine.Vector3(.2,1.1,.3)
runGroup('Tick',.016);approximate(l.lastPosition.y,1.68);approximate(l.lastPosition.x,0)
local previousPitch=FP.pitch
FP.pitch=80;runGroup('Tick',.016);approximate(l.lastPosition.y,1.68)
FP.pitch=-80;runGroup('Tick',.016);approximate(l.lastPosition.y,1.68)
FP.pitch=previousPitch
change('height_variation','true');change('head_translation','true');runGroup('Tick',.016)
approximate(l.lastPosition.y,1.18);approximate(l.lastPosition.x,.2);approximate(l.lastPosition.z,.38)
head.rotation=CS.UnityEngine.Quaternion.Euler(10,20,15)
change('head_rotation','true');change('head_tilt','true');change('head_strength','1');runGroup('Tick',.016)
local e=l.lastRotation.eulerAngles;approximate(e.x,10);approximate(e.y,20);approximate(e.z,15)
change('head_tilt','false');runGroup('Tick',.016);approximate(l.lastRotation.eulerAngles.z,0)
local input={CanMoveCam=function()return true end}
assert(FP.move(input,CS.UnityEngine.Vector2(50,0)));runGroup('Tick',.016);assert((turns or 0)>0)
input.CanMoveCam=function()return false end;assert(not FP.move(input,CS.UnityEngine.Vector2(1,1)))
change('fun_effects','true');runGroup('Tick',.016)
assert(l.overlay.activeSelf and l.maskRect.anchorMax.x==1 and not l.mask.raycastTarget and l.mask.color.a==1)
assert(l.mask.texture==l.maskTexture and l.maskTexture.applied)
assert(l.maskTexture.pixels[48*128].a>.99 and l.maskTexture.pixels[48*128+127].a==0)
local alpha=l.maskTexture.pixels[48*128+50].a;assert(alpha>0 and alpha<1,'soft rather than hard edge')
local oldTexture=l.maskTexture
CS.UnityEngine.Screen.width=2560;runGroup('Tick',.016)
assert(l.maskTexture~=oldTexture and oldTexture.destroyed,'regenerate once on aspect change')
rootCom.replicatedCharInfo.templateId='chr_0018_dapan';runGroup('Tick',.016)
assert(l.overlay.activeSelf and l.maskRect.anchorMax.x==1);approximate(l.mask.color.a,.35)
rootCom.replicatedCharInfo.templateId='chr_0002_endminm';runGroup('Tick',.016)
assert(l.volume.enabled and l.volume.gameObject.layer==8)
assert(l.scan.enabled.value and l.scan.enabled.overrideState and l.volume.profileRef==l.profile)
assert(l.volume.vfxEnableState and l.volume.priority>1000)
assert(l.scan.width.value<=1 and l.scan.smoothness.value>=1 and l.scan.maxFade.value>=5)
assert(l.overlay.activeSelf and l.mask.texture==l.scanTexture,'visible projection even if native scene pass is disabled')
assert(l.scan.progress.value>0 and l.scan.progress.value<50)
local resources=#objects
for i=1,500 do runGroup('Tick',.01)end
assert(#objects==resources,'scan loop must reuse component, not spawn each frame')
change('endmin_scan','false');runGroup('Tick',.016);assert(not l.volume.enabled and not l.volume.vfxEnableState and not l.overlay.activeSelf)
change('hide_self','false');runGroup('Tick',.016);assert(render1.shadowCastingMode==1 and render2.shadowCastingMode==0)
change('hide_self','true');change('show_body','false');runGroup('Tick',.016);runGroup('TailTick',.016)
assert(render1.shadowCastingMode==3 and render2.shadowCastingMode==3);approximate(head.localScale.x,1)
change('show_body','true');runGroup('Tick',.016);runGroup('TailTick',.016)
assert(render1.shadowCastingMode==1 and render2.shadowCastingMode==3);approximate(head.localScale.x,.001)
change('hide_self','true');runGroup('Tick',.016);render2.shadowCastingMode=1 -- Foreign renderer change must be preserved.
menuOpen=true;runGroup('Tick',.016)
assert(not FP.lease and render1.shadowCastingMode==1 and render2.shadowCastingMode==1)
assert(l.manager.curActiveController==baseLevel and l.camera.nearClipPlane==.2 and not l.volume.enabled)
approximate(head.localScale.x,1)
menuOpen=false;runGroup('Tick',.016);assert(FP.lease and FP.lease~=l)
local nextLease=FP.lease
local foreign={};nextLease.manager.curActiveController=foreign;nextLease.camera.fieldOfView=100
runGroup('Tick',.016);assert(not FP.lease and nextLease.manager.curActiveController==foreign and nextLease.camera.fieldOfView==100,
    'preserve foreign FOV even if it coincidentally equals our last value')
nextLease.manager.curActiveController=baseLevel
runGroup('Tick',.016);assert(FP.lease)
-- A foreign render override with the same native level controller must not be overwritten.
foreignOverride=true;FP.lease.brain.ActiveVirtualCamera={name='Foreign timeline'}
runGroup('Tick',.016);assert(not FP.lease);runGroup('Tick',.016);assert(not FP.lease)
foreignOverride=false;nextLease.brain.ActiveVirtualCamera=baseLevel.virtualCamera
runGroup('Tick',.016);assert(FP.lease)
failRemove=true;FP.hide(ctrl);assert(FP.lease and FP.lease.releasing)
failRemove=false;runGroup('Tick',.016);assert(not FP.lease,'cleanup survives hidden panel')
FP.show(ctrl);runGroup('Tick',.016);assert(FP.lease)
change('enabled','false');assert(not FP.lease and not FP.wanted)
FP.close(ctrl);assert(next(updates)==nil)
assert(#errors==0,'no adapter exceptions expected')
print('PASS production native adapter: lease/real math/FOV/heights/head tilt/native body setter/vision switch/reuse/foreign changes/cleanup retry')
-- A native pass failure must not remove the visible sensor sweep or the camera.
config.enabled='true';config.fun_effects='true';config.endmin_scan='true'
rootCom.replicatedCharInfo.templateId='chr_0003_endminf'
FP.show(ctrl);pressToggle=true;failScan=true;runGroup('Tick',.016);runGroup('TailTick',.016)
local fallback=assert(FP.lease)
assert(fallback.scanFailed and fallback.overlay.activeSelf and fallback.mask.texture==fallback.scanTexture)
local previousY=fallback.maskRect.anchorMax.y
runGroup('Tick',.25);assert(FP.lease==fallback and fallback.maskRect.anchorMax.y~=previousY)
-- Never overwrite a foreign bone-scale change while restoring our render mutation.
head.localScale=CS.UnityEngine.Vector3(.8,.8,.8)
FP.close(ctrl);assert(not FP.lease and next(updates)==nil);approximate(head.localScale.x,.8)
for _,o in ipairs(fallback.objects) do assert(o.destroyed,'fallback resources must be reclaimed') end
assert(#errors==1 and errors[1]:find('scan_render_unavailable',1,true))
failScan=false;head.localScale=CS.UnityEngine.Vector3(1,1,1)
print('PASS native scan failure fallback, animated sensor projection and foreign head-scale preservation')
