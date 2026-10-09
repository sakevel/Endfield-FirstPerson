local ctrl={}
FP.show(ctrl);assert(not FP.lease and registrations==1)
pressToggle=true;runGroup('Tick',1/60);runGroup('TailTick',1/60)
assert(FP.lease and FP.lease.manager.curActiveController==baseLevel and FP.lease.overrideId)
local l=FP.lease
approximate(l.camera.transform.position.y,1.68);approximate(l.camera.fieldOfView,85)
assert(render1.shadowCastingMode==1 and render2.shadowCastingMode==3,'body visible, only head renderer hidden')
approximate(head.localScale.x,.001)
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
local animatedRotation=head.localRotation
local originalHeadPosition=head.position
local animatedNeck=neck.localRotation
change('head_rotation','false');change('head_tilt','false');change('head_look_binding','true')
FP.yaw=35;FP.pitch=60
runGroup('Tick',.016);runGroup('TailTick',.016)
local aimed=CS.UnityEngine.Quaternion.Euler(60,35,0)
local eye=head.position+aimed*CS.UnityEngine.Vector3(0,.08,.08)
approximate(head.rotation.eulerAngles.x,60);approximate(head.rotation.eulerAngles.y,35)
assert(l.virtual.transform.parent==head and l.headRotationOwned and l.neckRotationOwned)
approximate(neck.rotation.eulerAngles.x,36);approximate(neck.rotation.eulerAngles.y,21)
assert(math.abs(head.position.z-originalHeadPosition.z)>.02,'head pivot must travel around neck, not just rotate in place')
for _,axis in ipairs({'x','y','z'})do
    approximate(l.camera.transform.position[axis],eye[axis]);approximate(l.virtual.transform.position[axis],eye[axis])
end
approximate(head.localScale.x,.001)
runGroup('Tick',.016)
approximate(head.localRotation.eulerAngles.x,animatedRotation.eulerAngles.x)
approximate(neck.localRotation.eulerAngles.x,animatedNeck.eulerAngles.x)
for _,axis in ipairs({'x','y','z'})do approximate(head.position[axis],originalHeadPosition[axis]) end
runGroup('TailTick',.016)
approximate(head.rotation.eulerAngles.x,60)
local beforeEye=l.lastPosition
for i=1,10 do runGroup('TailTick',.016)end
for _,axis in ipairs({'x','y','z'})do approximate(l.lastPosition[axis],beforeEye[axis]) end
change('head_look_binding','false')
assert(FP.lease==l and l.virtual.transform.parent==l.manager.virtualCamsRoot and not l.headRotationOwned)
approximate(head.localRotation.eulerAngles.x,animatedRotation.eulerAngles.x)
change('head_look_binding','true');runGroup('Tick',.016);runGroup('TailTick',.016)
head.localRotation=CS.UnityEngine.Quaternion.Euler(-15,12,8)
change('head_look_binding','false');approximate(head.localRotation.eulerAngles.x,-15)
head.localRotation=animatedRotation;change('head_rotation','true')
FP.yaw=0;FP.pitch=previousPitch
print('PASS physical head rotation, real head parenting, mounted eye arc, render-scale compensation, no accumulation and hot restoration')
local input={CanMoveCam=function()return true end}
assert(FP.move(input,CS.UnityEngine.Vector2(50,0)));runGroup('Tick',.016);assert((turns or 0)>0)
input.CanMoveCam=function()return false end;assert(not FP.move(input,CS.UnityEngine.Vector2(1,1)))
for i=1,120 do runGroup('Tick',1/60)end
change('turn_threshold','30');change('native_body_turn','true')
FP.yaw=FP.angle(rootCom.transform.eulerAngles.y+31)
local directBefore=turns or 0;local originalAction=pivot.m_turnStartMove
freezeNativeTurn=true;runGroup('Tick',.016)
assert(FP.lease.stepTurn and FP.lease.stepTurn.move.isActive and FP.turning and (turns or 0)==directBefore)
assert(pivot.m_turnStartMove~=originalAction and animationStarts==1 and privateAccessCount==3)
local requestCount=nativeRequests
for i=1,20 do runGroup('Tick',.016)end
assert(nativeRequests==requestCount and FP.turning,'native action not restarted or double-ticked')
freezeNativeTurn=false
for i=1,60 do runGroup('Tick',.016)end
assert(not FP.turning and pivot.m_turnStartMove==originalAction and not FP.lease.stepTurn and (turns or 0)==directBefore)
local mover=character.movementComponent
local stack=mover.rootMotionModifier
local startPos=rootCom.transform.position
FP.yaw=FP.angle(rootCom.transform.eulerAngles.y+70);runGroup('Tick',.016)
assert(l.stepTurn.translation and stack:GetValue().scale==0)
platformMotion=true
for i=1,30 do runGroup('Tick',.016)end
platformMotion=false
approximate(rootCom.transform.position.x,startPos.x)
assert(rootCom.transform.position.z>startPos.z,'moving platforms are not coordinate locked')
assert(not l.stepTurn and stack.m_overrideValues.Count==0 and stack:GetValue().scale==1)
change('turn_in_place','false')
startPos=rootCom.transform.position
FP.yaw=FP.angle(rootCom.transform.eulerAngles.y+70);runGroup('Tick',.016)
assert(l.stepTurn and not l.stepTurn.translation)
for i=1,30 do runGroup('Tick',.016)end
assert(rootCom.transform.position.x>startPos.x,'disabled option preserves native displacement')
change('turn_in_place','true')
stack:SetOverride(0x5a4d4c46,{scale=.75,disableCliffCheck=true})
FP.yaw=FP.angle(rootCom.transform.eulerAngles.y+70);runGroup('Tick',.016)
assert(l.stepTurn.translation.id==0x5a4d4c47 and stack:GetValue().scale==0)
change('turn_in_place','false')
assert(not l.stepTurn and stack.m_overrideValues.Count==1 and stack:GetValue().scale==.75)
change('turn_in_place','true');runGroup('Tick',.016)
assert(l.stepTurn.translation)
GameInstance.playerController.hasMoveInput=true;runGroup('Tick',.016)
assert(not l.stepTurn and stack.m_overrideValues.Count==1,'normal movement releases translation suppression')
GameInstance.playerController.hasMoveInput=false;FP.yaw=rootCom.transform.eulerAngles.y
stack:RemoveOverride(0x5a4d4c46)
FP.yaw=FP.angle(rootCom.transform.eulerAngles.y+70);runGroup('Tick',.016)
local id=l.stepTurn.translation.id
stack:SetOverride(id,{scale=.5,disableCliffCheck=true})
change('turn_in_place','false')
assert(stack.m_overrideValues.Count==1 and stack:GetValue().scale==.5)
stack:RemoveOverride(id);change('turn_in_place','true')
FP.yaw=FP.angle(rootCom.transform.eulerAngles.y+70);runGroup('Tick',.016)
local replacement=newModifierStack();replacement:SetOverride(id,{scale=.8,disableCliffCheck=true})
mover.rootMotionModifier=replacement;change('turn_in_place','false')
assert(stack.m_overrideValues.Count==0 and replacement.m_overrideValues.Count==1)
mover.rootMotionModifier=stack;change('turn_in_place','true')
FP.yaw=rootCom.transform.eulerAngles.y
print('PASS native translation scaling, optional displacement, platform movement, hot apply, input release and foreign modifier ownership')
local stopBase=nativeStops or 0
FP.yaw=FP.angle(rootCom.transform.eulerAngles.y-70);runGroup('Tick',.016)
menuOpen=true;runGroup('Tick',.016)
assert(stack.m_overrideValues.Count==0 and not FP.lease and pivot.m_turnStartMove==originalAction and nativeStops==stopBase+1,'menu restores action slot')
menuOpen=false;runGroup('Tick',.016);l=assert(FP.lease)
FP.yaw=FP.angle(rootCom.transform.eulerAngles.y+70);runGroup('Tick',.016)
local owned=l.stepTurn.move;local foreign={isActive=true};pivot.m_turnStartMove=foreign
freezeNativeTurn=true;runGroup('Tick',.016)
assert(pivot.m_turnStartMove==foreign and foreign.isActive and not owned.isActive and not l.stepTurn,'foreign slot preserved')
pivot.m_turnStartMove=originalAction;freezeNativeTurn=false;FP.turning=false
FP.yaw=rootCom.transform.eulerAngles.y;runGroup('Tick',.016)
local inputVector=character.movementComponent.input.moveVector
for _,gate in ipairs({'air','strafe','lock','rotating','moving','tag','disabled','pivot','cooldown','inactive'})do
    character.movementComponent.isInAir=gate=='air';strafe=gate=='strafe';rotator.lockToCamera=gate=='lock'
    rotator.isRotating=gate=='rotating';GameInstance.playerController.hasMoveInput=gate=='moving'
    blockNativeGate=gate=='tag';disableTurnStart=gate=='disabled';pivot.isPivoting=gate=='pivot'
    originalAction.m_remainingCd=gate=='cooldown' and 1 or 0;originalAction.enabled=gate~='inactive'
    FP.yaw=FP.angle(rootCom.transform.eulerAngles.y+70);runGroup('Tick',.016)
    assert(not l.stepTurn and pivot.m_turnStartMove==originalAction and character.movementComponent.input.moveVector==inputVector,gate)
end
character.movementComponent.isInAir=false;strafe=false;rotator.lockToCamera=false;rotator.isRotating=false
GameInstance.playerController.hasMoveInput=false;blockNativeGate=false;disableTurnStart=false;pivot.isPivoting=false
originalAction.m_remainingCd=0;originalAction.enabled=true
runGroup('Tick',.016);assert(l.stepTurn)
change('native_body_turn','false');assert(not l.stepTurn and pivot.m_turnStartMove==originalAction)
FP.turning=false;FP.yaw=rootCom.transform.eulerAngles.y;change('turn_threshold','90')
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
change('hide_self','true');runGroup('Tick',.016);render2.shadowCastingMode=1
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
config.enabled='true';config.fun_effects='true';config.endmin_scan='true'
rootCom.replicatedCharInfo.templateId='chr_0003_endminf'
FP.show(ctrl);pressToggle=true;failScan=true;runGroup('Tick',.016);runGroup('TailTick',.016)
local fallback=assert(FP.lease)
assert(fallback.scanFailed and fallback.overlay.activeSelf and fallback.mask.texture==fallback.scanTexture)
local previousY=fallback.maskRect.anchorMax.y
runGroup('Tick',.25);assert(FP.lease==fallback and fallback.maskRect.anchorMax.y~=previousY)
head.localScale=CS.UnityEngine.Vector3(.8,.8,.8)
FP.close(ctrl);assert(not FP.lease and next(updates)==nil);approximate(head.localScale.x,.8)
for _,o in ipairs(fallback.objects) do assert(o.destroyed,'fallback resources must be reclaimed') end
assert(#errors==1 and errors[1]:find('scan_render_unavailable',1,true))
failScan=false;head.localScale=CS.UnityEngine.Vector3(1,1,1)
print('PASS native scan failure fallback, animated sensor projection and foreign head-scale preservation')

config.enabled='true';config.fun_effects='false';config.native_body_turn='true';config.turn_threshold='30'
FP.show(ctrl);pressToggle=true;runGroup('Tick',.016)
local failedLease=assert(FP.lease);failNativeTurn=true;FP.yaw=FP.angle(rootCom.transform.eulerAngles.y+70)
local writes=turns or 0;local beforeErrors=#errors;runGroup('Tick',.016)
assert(FP.lease==failedLease and failedLease.nativeTurnUnavailable and not FP.failed)
for i=1,60 do runGroup('Tick',.016)end
assert(#errors==beforeErrors+1 and (turns or 0)==writes,'one diagnostic, no repeated exceptions or direct fallback')
failNativeTurn=false;change('native_body_turn','false');change('native_body_turn','true');runGroup('Tick',.016)
assert(not failedLease.nativeTurnUnavailable and failedLease.stepTurn,'toggle can retry the experimental API')
local beforeClose=pivot.m_turnStartMove
failNativeStop=true;FP.close(ctrl);assert(FP.lease and FP.lease.releasing and FP.lease.stepTurn,'failed native cleanup retained')
failNativeStop=false;runGroup('Tick',.016)
assert(not beforeClose.isActive and pivot.m_turnStartMove==originalAction and not FP.lease and next(updates)==nil)
print('PASS native animated turn action lease, curve completion, gates, no fake movement, original/foreign slot restoration and cleanup retry')

config.turn_in_place='true';FP.show(ctrl);pressToggle=true;runGroup('Tick',.016)
local partial=assert(FP.lease);failModifierAdd=true
FP.yaw=FP.angle(rootCom.transform.eulerAngles.y+70);runGroup('Tick',.016)
assert(partial.nativeTurnUnavailable and not partial.stepTurn and stack.m_overrideValues.Count==0)
assert(pivot.m_turnStartMove==originalAction)
failModifierAdd=false;change('turn_in_place','false');change('turn_in_place','true');runGroup('Tick',.016)
assert(partial.stepTurn.translation and stack:GetValue().scale==0)
failModifierRemove=true;FP.close(ctrl)
assert(FP.lease and FP.lease.releasing and FP.lease.stepTurn.translation,'retain modifier cleanup for retry')
failModifierRemove=false;runGroup('Tick',.016)
assert(not FP.lease and stack.m_overrideValues.Count==0 and pivot.m_turnStartMove==originalAction and next(updates)==nil)
print('PASS partial modifier acquisition rollback and failed modifier cleanup retry')

head.rotation=CS.UnityEngine.Quaternion.Euler(0,90,20)
config.head_look_binding='true';config.native_body_turn='false';config.turn_threshold='180'
config.head_rotation='false';config.head_tilt='false'
FP.show(ctrl);pressToggle=true;runGroup('Tick',.016)
local bound=assert(FP.lease);local basis=bound.baseHead
FP.yaw=FP.angle(rootCom.transform.eulerAngles.y+120);FP.pitch=70
runGroup('Tick',.016);runGroup('TailTick',.016)
local actualAim=head.rotation*CS.UnityEngine.Quaternion.Inverse(basis)
approximate(FP.angle(actualAim.eulerAngles.y-rootCom.transform.eulerAngles.y),85)
approximate(actualAim.eulerAngles.x,70)
assert(bound.virtual.transform.parent==head)
local originalBone=bound.headRotationOriginal
failHeadRestore=true;FP.close(ctrl)
assert(FP.lease and FP.lease.releasing and FP.lease.headRotationOwned,'head cleanup remains retryable')
failHeadRestore=false;runGroup('Tick',.016)
assert(not FP.lease and next(updates)==nil)
approximate(head.localRotation.eulerAngles.y,originalBone.eulerAngles.y)
assert(not bound.neckRotationOwned)
print('PASS rig-axis calibration, safe yaw limit and retryable head-pose cleanup')

FP.show(ctrl);pressToggle=true;runGroup('Tick',.016)
local coupled=assert(FP.lease)
FP.yaw=FP.angle(rootCom.transform.eulerAngles.y+40);FP.pitch=55
runGroup('Tick',.016);runGroup('TailTick',.016)
local savedNeck=coupled.neckRotationOriginal
failNeckRestore=true;FP.close(ctrl)
assert(FP.lease and FP.lease.neckRotationOwned and not FP.lease.headRotationOwned)
failNeckRestore=false;runGroup('Tick',.016)
assert(not FP.lease and next(updates)==nil)
approximate(neck.localRotation.eulerAngles.x,savedNeck.eulerAngles.x)
FP.show(ctrl);pressToggle=true;runGroup('Tick',.016)
FP.pitch=50;runGroup('Tick',.016);runGroup('TailTick',.016)
neck.localRotation=CS.UnityEngine.Quaternion.Euler(8,11,3)
change('head_look_binding','false');approximate(neck.localRotation.eulerAngles.x,8)
FP.close(ctrl)
print('PASS neck/head coupled pose, head spatial arc, neck restoration retry and foreign neck preservation')

config.head_look_binding='true'
local anim=character.animatorCom.animator
for i,height in ipairs({.08,.16,.24})do
    anim.isHuman=i~=3
    character.characterAnimCom=i==3 and {grounderIK={ik={references={head=head}}}} or nil
    neck.rotation=CS.UnityEngine.Quaternion.Euler(0,rootCom.transform.eulerAngles.y,0)
    head.localRotation=CS.UnityEngine.Quaternion.identity
    head.localPosition=CS.UnityEngine.Vector3(0,height,0)
    FP.show(ctrl);pressToggle=true;runGroup('Tick',.016)
    local rig=assert(FP.lease);assert(rig.neck==neck)
    local initialPos=head.position
    FP.yaw=FP.angle(rootCom.transform.eulerAngles.y+45);FP.pitch=65
    runGroup('Tick',.016)
    local preview=rig.lastPosition
    runGroup('TailTick',.016)
    for _,axis in ipairs({'x','y','z'})do approximate(rig.lastPosition[axis],preview[axis]) end
    assert(math.abs(head.position.y-initialPos.y)>.005,'neck articulation changes head height')
    assert(math.abs(head.position.x-initialPos.x)+math.abs(head.position.z-initialPos.z)>.02,'neck articulation moves head in space')
    FP.close(ctrl)
    for _,axis in ipairs({'x','y','z'})do approximate(head.position[axis],initialPos[axis]) end
end
anim.isHuman=true;character.characterAnimCom=nil
print('PASS 8/16/24 cm neck/head chains, actual spatial displacement, preview/final agreement and explicit nonhumanoid neck fallback')
