# HarmonyOS 打包文件说明

## 📦 文件类型对比

### HAP 文件（HarmonyOS Ability Package）

**定义**：
- HarmonyOS **单个模块**的应用包
- 包含一个 module 的所有资源和代码
- 文件扩展名：`.hap`

**特点**：
- ✅ 单个模块（如 entry 模块）
- ✅ 可以独立安装
- ✅ 适合单模块应用
- ✅ 文件较小

**示例**：
```
entry-default-signed.hap    ← 这是 HAP 文件
```

---

### APP 文件（HarmonyOS Application Package）

**定义**：
- HarmonyOS **完整应用**的应用包
- 包含应用的**所有 HAP 模块**
- 文件扩展名：`.app`

**特点**：
- ✅ 包含多个 HAP（entry + feature + ...）
- ✅ 完整的应用包
- ✅ 适合多模块应用
- ✅ 文件较大

**示例**：
```
PickCode.app
├── entry.hap       ← 主模块
├── feature1.hap    ← 功能模块1
└── feature2.hap    ← 功能模块2
```

---

## 📊 详细对比

| 特性 | HAP 文件 | APP 文件 |
|------|---------|----------|
| **包含内容** | 单个模块 | 所有模块 |
| **文件扩展名** | `.hap` | `.app` |
| **适用场景** | 单模块应用 | 多模块应用 |
| **文件大小** | 较小 | 较大 |
| **安装方式** | 独立安装 | 完整安装 |
| **上传商店** | ✅ 可以 | ✅ 可以 |

---

## 🎯 你的项目情况

### 当前构建输出

查看你的构建输出：
```
entry/build/default/outputs/default/
├── entry-default-signed.hap      ✅ 已签名的 HAP（推荐上传）
├── entry-default-unsigned.hap    ⚠️ 未签名的 HAP（不要上传）
├── app/
│   └── entry-default.hap         ℹ️ APP 目录下的 HAP
└── pack.info                     ℹ️ 打包信息
```

### 你的应用类型

**PickCode 是单模块应用**：
- 只有 `entry` 一个模块
- 没有其他 feature 模块
- 因此只生成 HAP 文件，**没有生成 APP 文件**

---

## ✅ 应该上传哪个文件？

### 推荐方案：上传 HAP 文件

**文件路径**：
```
entry/build/default/outputs/default/entry-default-signed.hap
```

**原因**：
- ✅ 这是**已签名**的 HAP 文件
- ✅ 单模块应用上传 HAP 即可
- ✅ 华为 AppGallery 支持直接上传 HAP
- ✅ 文件包含完整的应用内容

**文件大小**：约 364 KB

---

### ❌ 不要上传这些文件

**1. entry-default-unsigned.hap**
```
❌ 未签名的 HAP
❌ 无法通过 AppGallery 审核
```

**2. app/ 目录下的文件**
```
ℹ️ 这是用于本地调试的
ℹ️ 不需要上传
```

---

## 🤔 什么时候会有 APP 文件？

### 多模块应用才会生成 APP 文件

**示例项目结构**：
```
MyApp/
├── entry/              ← 主模块（必需）
├── feature1/           ← 功能模块1（可选）
├── feature2/           ← 功能模块2（可选）
└── library/            ← 库模块（可选）
```

**这种情况下构建会生成**：
```
outputs/default/
├── entry-default.hap       ← Entry 模块的 HAP
├── feature1-default.hap    ← Feature1 模块的 HAP
├── feature2-default.hap    ← Feature2 模块的 HAP
└── MyApp.app               ← 包含所有模块的 APP 文件 ✅
```

**这时应该上传**：
- ✅ `MyApp.app` - 完整应用包（推荐）
- 或分别上传每个 HAP 文件（不推荐）

---

## 📋 上传到 AppGallery 的步骤

### 步骤1：准备文件

```
文件：entry-default-signed.hap
路径：F:\HarmonyOS\PickCode\entry\build\default\outputs\default\
大小：约 364 KB
```

**检查清单**：
- ✅ 文件名包含 "signed"（已签名）
- ✅ 文件扩展名是 `.hap`
- ✅ 文件大小合理（几百 KB）

### 步骤2：登录 AppGallery Connect

```
访问：https://developer.huawei.com/consumer/cn/service/josp/agc/index.html
→ 我的应用
→ 选择 PickCode
```

### 步骤3：上传软件包

```
→ 版本信息
→ 软件包管理
→ 上传软件包
→ 选择文件：entry-default-signed.hap
→ 确认上传
```

### 步骤4：填写版本信息

```
软件版本号：1.0.0
版本说明：初始版本
更新类型：首次发布
```

### 步骤5：提交审核

```
→ 保存
→ 提交审核
→ 等待审核结果（1-3个工作日）
```

---

## 🔍 如何区分文件？

### 查看文件名

```
✅ entry-default-signed.hap
   ↑         ↑        ↑
   模块名   签名状态  文件类型

❌ entry-default-unsigned.hap
   ↑         ↑           ↑
   模块名   未签名      文件类型
```

### 查看文件大小

```
entry-default-signed.hap      364 KB  ✅ 较大（包含签名）
entry-default-unsigned.hap    323 KB  ❌ 较小（无签名）
```

---

## 💡 常见问题

### Q1: 为什么我没有看到 .app 文件？

**A**: 因为你的应用只有一个模块（entry）。

单模块应用不会生成 .app 文件，只生成 .hap 文件。这是正常的！

### Q2: HAP 和 APP 哪个更好？

**A**: 取决于应用结构。

- **单模块应用**（你的情况）：只有 HAP ✅
- **多模块应用**：建议上传 APP 包 ✅

### Q3: 上传 HAP 还是 APP 到 AppGallery？

**A**: 对于单模块应用（你的情况）：

- ✅ 上传 `entry-default-signed.hap`
- 这就是完整的应用，AppGallery 完全支持

### Q4: 可以同时上传 HAP 和 APP 吗？

**A**: 不能。

- 每个版本只能上传一种类型
- 单模块应用只有 HAP，没有 APP
- 选择其中之一即可

### Q5: app/ 目录下的 HAP 文件是什么？

**A**: 这是用于**本地调试**的文件。

```
entry/build/default/outputs/default/app/entry-default.hap
```

- 这是未签名的调试版本
- 用于 DevEco Studio 本地调试
- **不要上传到 AppGallery**

---

## 📊 文件选择流程图

```
开始
  ↓
检查应用结构
  ↓
┌─────────────────────┐
│ 是单模块应用？      │
└─────────────────────┘
  ↓                 ↓
 是                 否
  ↓                 ↓
上传 HAP 文件       上传 APP 文件
  ↓                 ↓
entry-default-     MyApp.app
signed.hap         (包含所有模块)
  ↓                 ↓
  └────────┬────────┘
          ↓
    AppGallery Connect
          ↓
      提交审核
          ↓
        完成
```

---

## ✅ 总结

### 你的情况

**项目**：PickCode（单模块应用）

**构建产物**：
- ✅ `entry-default-signed.hap` - **上传这个**
- ❌ `entry-default-unsigned.hap` - 不要上传
- ℹ️ 没有 .app 文件 - 这是正常的

### 上传文件

```
文件名：entry-default-signed.hap
路径：entry/build/default/outputs/default/
大小：364 KB
类型：已签名的 HAP 文件
用途：上传到 AppGallery Connect ✅
```

### 关键要点

1. **HAP vs APP**：
   - HAP = 单个模块
   - APP = 多个模块打包
   
2. **你的应用**：
   - 单模块应用
   - 只有 HAP，没有 APP
   
3. **应该上传**：
   - `entry-default-signed.hap` ✅
   
4. **不要上传**：
   - unsigned 文件 ❌
   - app/ 目录下的文件 ❌

---

**创建时间**：2025-10-25  
**适用版本**：HarmonyOS API 11+  
**项目**：PickCode

