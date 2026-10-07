# 图标设计与导出说明

本文档说明 Endfield-FirstPerson 的图标规范与导出流程。

---

## 图标规范

- **模组图标** (`mod/icon.png`)：
  256×256 透明 RGBA PNG。
  采用终末地工业风格设计，主体为棱角取景视窗与眼睛轮廓，辅以 `#ffef00` 亮黄点缀三角标，表达第一人称视角观测。

---

## 导出流程

从高分辨率源图生成发布图标：

```powershell
./tools/export-icon.ps1 -Source assets/icon-source.png -Destination mod/icon.png
```
