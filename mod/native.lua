local U=CS.UnityEngine
local V,Q=U.Vector3,U.Quaternion
local R=U.Rendering
local ID='first-person'
assert(not rawget(_G,'ZMLFirstPerson'),'first-person namespace occupied')
local function live(o) return o~=nil and not o:Equals(nil) end
local function copy(v) return V(v.x,v.y,v.z) end
local function angle(x) return (x+180)%360-180 end
local function near(a,b) return math.abs(a-b)<.001 end
local function own(l,o)
    assert(o,'owned resource unavailable');l.objects[#l.objects+1]=o;return o
end
local function object(l,name) return own(l,U.GameObject(name)) end
local function settingsApi()
    local f=assert(loadstring(LuaManagerInst:LoadLua('ZML/Api'),'@ZML/Api'))
    return f()
end
local api=settingsApi()
local function reportEvent(event,err)
    pcall(api.report,ID,event)
    if err then pcall(function() logger.error('ZML FirstPerson: '..event..': '..tostring(err):gsub('[%c]',' '):sub(1,384)) end) end
end
local P={report=reportEvent}
local action,M,owner,unsubscribe,keys,cleanupKey
local function ensureKeys()
    require_ex('Common/Utils/UIUtils')
    if not rawget(_G,'ZMLKeybinds') then require_ex('UI/Panels/GameSetting/GameSettingCtrl') end
    local k=assert(rawget(_G,'ZMLKeybinds'),'keybinds dependency unavailable')
    assert(k.api==1,'keybinds version unavailable')
    if k._attachGate then k._attachGate() end
    action=k.find(ID,'toggle') or assert(k.register(ID,{id='toggle',name='第一人称 · 切换视角',primary='Ctrl+F5',secondary='None'}))
    assert(type(action.pressed)=='function','keybinds continuous input API required')
end
function P.pressed() return action and action.pressed() or false end
function P.character()
    local pc=GameInstance.playerController
    local ch=pc and pc.mainCharacter
    if not ch or not ch:IsValid() or not ch.alive or ch.inCinematic then return nil end
    return ch
end
function P.allowed(ch)
    local pc=GameInstance.playerController
    if not U.Application.isFocused or not GameInstance.isInGameplay or pc.blockPlayerInput then return false end
    if InputManager.cursorVisible or not UIUtils.IsPhaseLevelOnTop() then return false end
    if LuaSystemManager.factory.inTopView or Utils.isInCustomAbility() then return false end
    local mgr=GameInstance.cameraManager
    if not mgr or mgr:IsCommonTempControllerActive() then return false end
    local level=mgr:GetMainLevelCameraController()
    local current=mgr.curActiveController
    if not level or current~=level then return false end
    local brain=mgr.cinemachineBrainCpt
    if not live(brain) or brain.IsBlending then return false end
    local active=brain.ActiveVirtualCamera
    return active==level.virtualCamera or (M.lease and active==M.lease.virtual and not M.lease.releasing)
end
function P.capture(ch)
    local root=assert(ch.rootCom,'character root unavailable')
    local animator=assert(ch.animatorCom and ch.animatorCom.animator,'character animator unavailable')
    local grounder=ch.characterAnimCom and ch.characterAnimCom.grounderIK
    local refs=grounder and grounder.ik and grounder.ik.references
    local head=refs and refs.head
    if not live(head) and animator.isHuman then head=animator:GetBoneTransform(U.HumanBodyBones.Head) end
    assert(live(head) and live(root.transform),'head bone unavailable')
    local mgr=assert(GameInstance.cameraManager,'camera manager unavailable')
    local cam=assert(mgr.mainCamera,'main camera unavailable')
    local e=cam.transform.eulerAngles
    local base=Q.Inverse(root.transform.rotation)*head.rotation
    local neutral=Q.Inverse(root.transform.rotation)*(head.position-root.transform.position)
    assert(neutral.y>.2 and neutral.y<4,'head height outside supported rig')
    return {character=ch,root=root,head=head,manager=mgr,originalController=mgr:GetMainLevelCameraController(),
        camera=cam,brain=assert(mgr.cinemachineBrainCpt),originalFov=cam.fieldOfView,originalNear=cam.nearClipPlane,
        objects={},renderers={},neutral=neutral,baseHead=base,localEye=copy(neutral),yaw=e.y,pitch=angle(e.x)}
end
function P.id(l)
    local data=l.root.replicatedCharInfo
    if data then return data.templateId end
    return nil
end
local function rendererSettings(l,c)
    local mode=c.hide_self and (c.show_body and 'head' or 'full') or 'none'
    if l.visualMode==mode then return end
    if mode~='none' then
        if not l.rendererCaptured then
            local model=l.root.model
            assert(live(model),'character render model unavailable')
            local renderers=model:GetComponentsInChildren(typeof(U.Renderer),true)
            assert(renderers.Length<=256,'character renderer count changed')
            for i=0,renderers.Length-1 do
                local r=renderers[i]
                local name=(r.name or ''):lower()
                local headOnly=r.transform:IsChildOf(l.head) or name:find('face',1,true) or
                    name:find('hair',1,true) or name:find('head',1,true)
                l.renderers[#l.renderers+1]={object=r,original=r.shadowCastingMode,headOnly=headOnly and true or false}
            end
            l.rendererCaptured=true
        end
    end
    for _,r in ipairs(l.renderers) do
        local hide=mode=='full' or (mode=='head' and r.headOnly)
        if live(r.object) then
            if r.owned and not hide and r.object.shadowCastingMode==R.ShadowCastingMode.ShadowsOnly then
                r.object.shadowCastingMode=r.original;r.owned=false
            elseif hide and not r.owned then
                r.original=r.object.shadowCastingMode
                r.object.shadowCastingMode=R.ShadowCastingMode.ShadowsOnly;r.owned=true
            end
        end
    end
    l.visualMode=mode
end
local function sameVector(a,b)
    return math.abs(a.x-b.x)<1e-6 and math.abs(a.y-b.y)<1e-6 and math.abs(a.z-b.z)<1e-6
end
local function restoreHead(l)
    if not l.headScaleOwned then return end
    if live(l.head) and sameVector(l.head.localScale,l.headScaleApplied) then
        l.head.localScale=l.headScaleOriginal
    end
    l.headScaleOwned=false
end
local function hideHeadForRender(l,c)
    if not c.hide_self or not c.show_body then restoreHead(l);return end
    if not l.headScaleOwned then
        l.headScaleOriginal=copy(l.head.localScale)
        l.headScaleApplied=l.headScaleOriginal*.001
        l.headScaleOwned=true
    end
    l.head.localScale=l.headScaleApplied
end
function P.install(l,c)
    local go=object(l,'ZML FirstPerson Camera')
    go.transform:SetParent(l.manager.virtualCamsRoot,false)
    l.virtual=assert(go:AddComponent(typeof(CS.Cinemachine.CinemachineVirtualCamera)),'virtual camera unavailable')
    l.virtual.Priority=-100
    local lens=l.virtual.m_Lens
    lens.NearClipPlane=.035;lens.FarClipPlane=l.camera.farClipPlane;lens.FieldOfView=c.fov
    l.virtual.m_Lens=lens
    P.pose(l,l.yaw,l.pitch,c,0)
    l.overrideId=l.brain:SetCameraOverride(-1,nil,l.virtual,1,0)
    assert(type(l.overrideId)=='number' and l.overrideId>=0,'camera override rejected')
    l.activationFrame=U.Time.frameCount
    l.installed=true
    rendererSettings(l,c)
    reportEvent('entered')
end
function P.ownsCamera(l)
    return live(l.virtual) and l.overrideId~=nil and l.manager.curActiveController==l.originalController and
        (l.brain.ActiveVirtualCamera==l.virtual or (U.Time.frameCount==l.activationFrame and l.brain.ActiveVirtualCamera==l.originalController.virtualCamera))
end
function P.bodyYaw(l) return l.root.transform.eulerAngles.y end
function P.canTurn(l)
    local pc=GameInstance.playerController
    local m=l.character.movementComponent
    return m and m.enabled and not pc.blockPlayerInput and not pc.castingNormalAttack and
        not l.character.inCinematic and not m.isClimbing and not m.inSkillAir
end
function P.turn(l,yaw)
    l.root.rotation=Q.Euler(0,yaw,0)
end
function P.pose(l,yaw,pitch,c,dt,postAnimation)
    assert(live(l.head) and live(l.root.transform) and live(l.virtual),'camera rig destroyed')
    local body=l.root.transform
    local localHead=Q.Inverse(body.rotation)*(l.head.position-body.position)
    local wanted=V(c.head_translation and localHead.x or l.neutral.x,
        c.height_variation and localHead.y or l.neutral.y,
        c.head_translation and localHead.z or l.neutral.z)
    if c.smoothing==0 then l.localEye=copy(wanted)
    elseif postAnimation then l.localEye=V.Lerp(l.localEye,wanted,1-math.exp(-dt/c.smoothing)) end
    local baseRotation=Q.Euler(pitch,yaw,0)
    local eye=body.position+Q.Euler(0,body.eulerAngles.y,0)*l.localEye+V(0,c.eye_offset,0)+Q.Euler(0,yaw,0)*V(0,0,c.forward_offset)
    local delta=Q.Inverse(body.rotation)*l.head.rotation*Q.Inverse(l.baseHead)
    local e=delta.eulerAngles
    local rotation=baseRotation*Q.Euler(c.head_rotation and angle(e.x)*c.head_strength or 0,
        c.head_rotation and angle(e.y)*c.head_strength or 0,c.head_tilt and angle(e.z)*c.head_strength or 0)
    l.virtual:SetFieldOfView(c.fov)
    l.virtual:ForceCameraPosition(eye,rotation)
    if l.overrideId then
        l.originalController.param:SetHorizontalAngle(yaw,false)
        local handle=l.brain:SetCameraOverride(l.overrideId,nil,l.virtual,1,dt)
        assert(handle==l.overrideId,'camera override handle changed')
    end
    l.lastPosition,l.lastRotation,l.lastFov=copy(eye),rotation,c.fov
    rendererSettings(l,c)
end
local function tail(dt)
    local l=M.lease
    if not l or l.releasing or not P.ownsCamera(l) or not P.allowed(l.character) then return end
    P.pose(l,M.yaw,M.pitch,M.settings,math.max(0,math.min(dt or 0,.1)),true)
    if not l.manager.cinemachineBrainCpt.IsBlending then
        l.camera.transform:SetPositionAndRotation(l.lastPosition,l.lastRotation)
        l.camera.fieldOfView=M.settings.fov;l.camera.nearClipPlane=.035
        l.actualOwned=true
        hideHeadForRender(l,M.settings)
    end
end
local function overlay(l)
    if live(l.overlay) then return end
    local go=object(l,'ZML FirstPerson Vision')
    local canvas=go:AddComponent(typeof(U.Canvas))
    canvas.renderMode=U.RenderMode.ScreenSpaceOverlay;canvas.sortingOrder=-10
    local imageGo=object(l,'Vision Mask')
    local rect=imageGo:AddComponent(typeof(U.RectTransform))
    rect:SetParent(go.transform,false)
    rect.anchorMin=U.Vector2(0,0);rect.anchorMax=U.Vector2(1,1)
    rect.offsetMin=U.Vector2.zero;rect.offsetMax=U.Vector2.zero
    local image=imageGo:AddComponent(typeof(U.UI.RawImage));image.raycastTarget=false
    l.overlay,l.mask,l.maskRect=go,image,rect
    go:SetActive(false)
end
local function texture(l,w,h,pixel)
    local tex=own(l,U.Texture2D(w,h,U.TextureFormat.RGBA32,false))
    tex.wrapMode=U.TextureWrapMode.Clamp;tex.filterMode=U.FilterMode.Bilinear
    for y=0,h-1 do for x=0,w-1 do tex:SetPixel(x,y,pixel((x+.5)/w,(y+.5)/h)) end end
    tex:Apply(false,true)
    return tex
end
local function eyepatch(l)
    local aspect=U.Screen.width/math.max(1,U.Screen.height)
    if l.maskTexture and near(l.maskAspect,aspect) then return end
    local tex=texture(l,128,96,function(x,y) return U.Color(0,0,0,M.eyepatchAlpha(x,y,aspect)) end)
    local old=l.maskTexture
    l.maskTexture,l.maskAspect=tex,aspect
    if old then
        for i,o in ipairs(l.objects) do if o==old then table.remove(l.objects,i);break end end
        U.Object.Destroy(old)
    end
end
local function scanProjection(l)
    overlay(l)
    if l.scanTexture then return end
    l.scanTexture=texture(l,8,128,function(_,y)
        local a=math.exp(-((y-.5)/.13)^2)*.24
        return U.Color(.25,.9,1,a)
    end)
end
local function acceptedVolumeLayer(mask)
    assert(mask~=0,'main camera has no volume layers')
    for i=0,31 do if math.floor(mask/2^i)%2==1 then return i end end
    error('volume layer unavailable')
end
local function parameter(scan,key,value)
    local p=assert(scan[key],'scan render parameter missing: '..key)
    p.value=value;p.overrideState=true
end
local function scanVolume(l)
    if live(l.volume) then return end
    local go=object(l,'ZML FirstPerson Inhibitor Scan')
    go.layer=acceptedVolumeLayer(l.manager:GetMainCameraVolumeLayerMask())
    local volume=go:AddComponent(typeof(R.Volume));volume.enabled=false
    local profile=own(l,U.ScriptableObject.CreateInstance(typeof(R.VolumeProfile)))
    l.profile=profile
    local scan=profile:Add(typeof(CS.HG.Rendering.Runtime.HGScanLine),false)
    l.scan=own(l,scan)
    parameter(scan,'enabled',true)
    parameter(scan,'progress',0)
    parameter(scan,'minDistance',0);parameter(scan,'maxDistance',50)
    parameter(scan,'width',.6);parameter(scan,'interval',.1)
    parameter(scan,'smoothness',10);parameter(scan,'maxFade',40)
    parameter(scan,'color',U.Color(.2,.85,1,1))
    parameter(scan,'distortIntensity',.04);parameter(scan,'charBrightIntensity',.3)
    parameter(scan,'highlightWidth',1);parameter(scan,'highlightThickness',.15)
    parameter(scan,'colorHighlight',U.Color(.5,1,1,1))
    volume:SetInstantiatedProfile(profile)
    volume.isGlobal=true;volume.priority=100000;volume.weight=1
    l.volume=volume
end
function P.effects(l,effect,c,dt)
    if effect=='scan' then
        l.scanTime=((l.scanTime or 0)+dt)%c.scan_period
        scanProjection(l)
        local y=-.16+1.32*l.scanTime/c.scan_period
        l.maskRect.anchorMin=U.Vector2(0,y-.12);l.maskRect.anchorMax=U.Vector2(1,y+.12)
        l.mask.texture=l.scanTexture;l.mask.color=U.Color(1,1,1,1);l.overlay:SetActive(true)
    else l.scanTime=0 end
    if effect=='scan' and not l.scanFailed then
        local ok,err=pcall(function()
            scanVolume(l)
            parameter(l.scan,'progress',50*l.scanTime/c.scan_period)
            local p=l.root.transform.position
            parameter(l.scan,'centerPos',U.Vector4(p.x,p.y,p.z,1))
            l.volume.gameObject.layer=acceptedVolumeLayer(l.manager:GetMainCameraVolumeLayerMask())
            l.volume.enabled=true
            l.volume:Play()
        end)
        if not ok then
            l.scanFailed=true
            if live(l.volume) then l.volume.enabled=false end
            reportEvent('scan_render_unavailable',err)
        end
    elseif live(l.volume) then l.volume:Stop();l.volume.enabled=false end
    if effect=='eyepatch' or effect=='sunglasses' then
        overlay(l)
        l.maskRect.anchorMin=U.Vector2(0,0);l.maskRect.anchorMax=U.Vector2(1,1)
        if effect=='eyepatch' then
            eyepatch(l);l.mask.texture=l.maskTexture;l.mask.color=U.Color(1,1,1,1)
        else l.mask.texture=U.Texture2D.whiteTexture;l.mask.color=U.Color(0,0,0,c.sunglasses_darkness) end
        l.overlay:SetActive(true)
    elseif effect~='scan' and live(l.overlay) then l.overlay:SetActive(false) end
end
function P.release(l)
    l.releasing=true
    local success=true
    local restoreActual=false
    local function attempt(fn) if not pcall(fn) then success=false end end
    if l.actualOwned then attempt(function()
        if live(l.brain) then
            restoreActual=l.manager.curActiveController==l.originalController and
                (l.brain.ActiveVirtualCamera==l.virtual or l.brain.ActiveVirtualCamera==l.originalController.virtualCamera)
        end
    end) end
    attempt(function() restoreHead(l) end)
    if live(l.volume) then attempt(function() l.volume:Stop();l.volume.enabled=false end) end
    if live(l.overlay) then attempt(function() l.overlay:SetActive(false) end) end
    for _,r in ipairs(l.renderers) do
        if r.owned then attempt(function()
            if live(r.object) and r.object.shadowCastingMode==R.ShadowCastingMode.ShadowsOnly then r.object.shadowCastingMode=r.original end
            r.owned=false
        end) end
    end
    if l.overrideId then attempt(function()
        if live(l.brain) then l.brain:ReleaseCameraOverride(l.overrideId) end
        l.overrideId=nil
    end) end
    if l.actualOwned then attempt(function()
        if restoreActual and live(l.camera) then
            if near(l.camera.nearClipPlane,.035) then l.camera.nearClipPlane=l.originalNear end
            if near(l.camera.fieldOfView,l.lastFov) then l.camera.fieldOfView=l.originalFov end
        end
        l.actualOwned=false
    end) end
    if success then
        for i=#l.objects,1,-1 do attempt(function()
            local o=l.objects[i];if live(o) then U.Object.Destroy(o) end;l.objects[i]=nil
        end) end
    end
    return success
end
M=ZMLFPFactory(P)
local function guarded(fn,...)
    local ok,err=pcall(fn,...)
    if not ok then M.fault(err) end
end
local function detach()
    for _,key in ipairs(keys or {}) do pcall(function() LuaUpdate:Remove(key) end) end;keys={}
    if unsubscribe then pcall(unsubscribe);unsubscribe=nil end
end
local function cleanupRetry()
    if not M.lease or cleanupKey then return end
    cleanupKey=LuaUpdate:Add('Tick',function()
        local ok,done=pcall(M.release)
        if ok and done then LuaUpdate:Remove(cleanupKey);cleanupKey=nil end
    end)
end
function M.show(ctrl)
    if owner and owner~=ctrl then M.hide(owner) end
    owner=ctrl;detach()
    local ok,err=pcall(function()
        ensureKeys()
        M.configure(assert(api.get(ID)))
        unsubscribe=api.subscribe(ID,function(_,_,values) guarded(M.configure,values) end)
        keys={LuaUpdate:Add('Tick',function(dt) guarded(function()
                if M.lease then restoreHead(M.lease) end
                M.frame(dt)
            end) end),
            LuaUpdate:Add('TailTick',function(dt) guarded(tail,dt) end)}
        reportEvent('ready')
    end)
    if not ok then detach();M.fault(err);cleanupRetry() end
end
function M.hide(ctrl)
    if owner~=ctrl then return end
    detach();owner=nil
    pcall(M.release);cleanupRetry()
end
function M.close(ctrl)
    if owner and owner~=ctrl then return end
    M.hide(ctrl);M.wanted=false;pcall(M.release);cleanupRetry()
end
function M.move(ctrl,delta)
    if not ctrl:CanMoveCam() or not M.lease or M.lease.releasing or not P.ownsCamera(M.lease) then return false end
    if not P.allowed(M.lease.character) then return false end
    local x,y=delta.x,delta.y
    if DeviceInfo.usingKeyboard then
        if x==0 then x=InputManagerInst:GetAxis('Mouse X')*.9 end
        if y==0 then y=InputManagerInst:GetAxis('Mouse Y')*.63 end
    elseif DeviceInfo.usingController then x=x*90;y=y*90 end
    local ok,result=pcall(M.look,x,y)
    if not ok then M.fault(result);return false end
    return result
end
_G.ZMLFirstPerson=M
return M
