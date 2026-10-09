# 原生客户端接口与第一人称架构

本文档记录 Endfield-FirstPerson 模组的相机接管机制、Cinemachine 渲染管线交互、角色骨骼跟随以及专属视野效果的实现架构。

---

## 1. 相机控制与 Cinemachine 接入

### 1.1 输入捕获与接管
- 原生视角输入汇聚于 `LevelCameraCtrl._MoveCamera(self, delta)` 与 `ZoomCamera`。
- 模组通过在 `LevelCameraCtrl` 注入钩子：
  - 在第一人称激活状态下消费鼠标/手柄视角增量，驱动内部偏航角（Yaw）与俯仰角（Pitch）；
  - 保留原生 `CanMoveCam()` 状态检查，在菜单、过场动画或特殊技能释放时自动让渡控制权。

### 1.2 Cinemachine 虚拟相机覆盖
- 通过 `GameInstance.cameraManager` 获取全局 `cinemachineBrainCpt`。
- 使用 `CinemachineBrain.SetCameraOverride` 获取渲染租约，动态注册并激活模组创建的自有虚拟相机 (`CinemachineVirtualCamera`)。
- 自有相机优先级设为最低，退出第一人称或触发原生过场时通过 `ReleaseCameraOverride` 立即安全释放，由游戏原生相机平滑接管。

### 1.3 视点定位与眼高稳定
- 视点位置基于角色根坐标、头部骨骼高度偏移与水平前移向量推导。
- 视点前移向量严格沿水平偏航方向延伸，俯仰旋转仅改变相机视线，不影响垂直眼高。

---

## 2. 骨骼跟随与转身控制

### 2.1 头颈骨骼联动与真实眼位绑定
- 优先从 `CharacterAnimCom.grounderIK.ik.references.head` 获取头部 Transform，回退方案使用 `Animator.GetBoneTransform(HumanBodyBones.Head)`，并从 `HumanBodyBones.Neck` 获取颈部骨骼。
- 开启头颈联动时：
  - 颈部承担视角俯仰与偏航的部分旋转，头部补足剩余朝向，并对骨骼扭转设置横向安全限幅；
  - 镜头绑定至头部骨骼，眼位沿颈部关节真实弧线运动，在 TailTick 阶段更新骨骼姿势，逐帧还原避免旋转累积。

### 2.2 身体朝向与自动平滑转身
- 实时计算相机视线偏航角与角色根节点朝向的相对夹角。
- 当夹角绝对值超过 `turn_threshold`（默认 90°，范围 0°~180°）时启动平滑转身状态机，按配置的角速度通过角色旋转驱动躯干朝向视线。

### 2.3 原生迈步转身动作接入
- 支持通过 `CharacterTurnStartMove` 触发游戏原生的起步与迈步转身动画曲线，由动画驱动身体转向。
- 提供「原生转身保持原地」选项：通过 `MovementComponent.AddRootMotionModifier` 临时缩放动画位移，在保留脚步动画与转身效果的同时避免位置漂移，并在动作结束或受到移动输入打断时安全移除修改器。

---

## 3. 模型可见性与专属视觉效果

### 3.1 身体可见性与头部隐藏
- 默认开启第一人称身体可见模式：
  - 遍历角色模型各 Renderer，将属于头部/面部/发型的渲染组件临时切换为 `ShadowsOnly`；
  - 针对混合权重网格，在 `TailTick` 阶段对头部骨骼进行局部微缩放，并在下一帧 Tick 前恢复，避免视线遮挡同时保留躯干与四肢。

### 3.2 角色专属趣味视野
通过 `rootCom.replicatedCharInfo.templateId` 识别当前主控角色并激活对应特效：
- **汤汤 (`chr_0027_tangtang`)**：
  基于屏幕宽高比动态生成圆弧形 smoothstep 渐变纹理，通过全屏 UI 画布实现眼罩遮挡效果。
- **管理员 (`chr_0002_endminm` / `chr_0003_endminf`)**：
  实例化专用 Volume 并附加 `HG.Rendering.Runtime.HGScanLine` 组件，同时叠加扫描投影光带，产生周期性扫描波纹。
- **大潘 (`chr_0018_dapan`)**：
  使用全屏半透明黑色调色层实现墨镜暗化效果，深度可在配置中调节。
