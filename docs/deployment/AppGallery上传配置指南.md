# AppGallery 上传配置指南

## 🚨 错误码 993 解决方案

### 问题描述
```
错误码：993
错误信息：Profile文件非法
```

### 问题原因
当前使用的是 DevEco Studio 自动生成的**调试签名**，不能用于发布到 AppGallery。

---

## ✅ 解决步骤

### 步骤1：在华为开发者后台创建应用

#### 1.1 访问开发者后台
```
https://developer.huawei.com/consumer/cn/service/josp/agc/index.html
```

#### 1.2 创建应用
```
1. 登录华为开发者账号
2. AppGallery Connect → 我的应用 → 添加应用
3. 选择：HarmonyOS 应用
4. 填写应用信息：
   应用名称：PickCode
   包名：com.mtx.take.code  ← 必须与项目一致！
5. 点击"确定"创建
```

---

### 步骤2：生成密钥和证书

#### 2.1 生成密钥库和 CSR（如果还没有）

**在 DevEco Studio 中：**

```
菜单栏 → Build → Generate Key and CSR

填写信息：
├── Key Store File: signature/release.p12
├── Password: [输入强密码，至少32位]
├── Confirm: [再次输入密码]
├── Alias: release_key
├── Key Password: [输入密钥密码，至少32位]
├── Validity (Years): 25
├── Certificate:
│   ├── First and Last Name: Your Name
│   ├── Organizational Unit: Your Team
│   ├── Organization: MTX
│   ├── City or Locality: Your City
│   ├── State or Province: Your Province
│   └── Country Code (XX): CN
└── 点击 OK
```

**会生成两个文件：**
- `signature/release.p12` - 密钥库文件
- `signature/release.csr` - 证书签名请求

#### 2.2 在开发者后台申请证书

```
AppGallery Connect → 我的应用 → PickCode
→ HarmonyOS 应用 → 应用签名
→ 创建证书
→ 上传 release.csr 文件
→ 下载证书（release.cer）
→ 保存到 signature/release.cer
```

---

### 步骤3：下载发布 Profile

#### 3.1 创建发布 Profile

```
AppGallery Connect → 我的应用 → PickCode
→ HarmonyOS 应用 → 应用签名
→ Profile 管理 → 新增 Profile

配置信息：
├── Profile 类型: 发布  ← 重要！
├── 设备调试类型: 生产设备
├── 证书: [选择刚才创建的证书]
├── Bundle ID: com.mtx.take.code  ← 必须匹配
└── 点击"生成"
```

#### 3.2 下载 Profile

```
→ 下载 Profile（release_profile.p7b）
→ 保存到 signature/release.p7b
```

---

### 步骤4：更新项目构建配置

#### 4.1 编辑 build-profile.json5

将签名配置改为使用正式签名文件：

```json5
{
  "app": {
    "signingConfigs": [
      {
        "name": "release",
        "type": "HarmonyOS",
        "material": {
          "storeFile": "signature/release.p12",
          "storePassword": "[你的密钥库密码]",
          "keyAlias": "release_key",
          "keyPassword": "[你的密钥密码]",
          "signAlg": "SHA256withECDSA",
          "certpath": "signature/release.cer",
          "profile": "signature/release.p7b"
        }
      }
    ],
    "products": [
      {
        "name": "default",
        "signingConfig": "release",  // ← 使用 release 签名
        // ...
      }
    ]
  }
}
```

#### 4.2 验证配置

确保以下信息一致：
- ✅ bundleName: `com.mtx.take.code`
- ✅ Profile 文件中的 Bundle ID: `com.mtx.take.code`
- ✅ keyAlias: `release_key` (不是 debugKey)
- ✅ Profile 类型: **发布**（不是调试）

---

### 步骤5：重新构建应用

#### 5.1 清理旧的构建

```bash
Build → Clean Project
```

#### 5.2 构建发布版本

```bash
Build → Build Hap(s)/App(s) → Build App(s)
```

#### 5.3 找到签名后的包

```
entry/build/default/outputs/default/
└── entry-default-signed.hap  ← 这个是签名后的包
```

---

### 步骤6：上传到 AppGallery

#### 6.1 准备应用信息

在开发者后台填写：
```
→ 版本信息
  ├── 软件版本: 1.0.0
  ├── 更新说明: 初始版本
  └── 上传 HAP 包: entry-default-signed.hap

→ 应用信息
  ├── 应用名称: PickCode - 快递取件码管理
  ├── 应用简介: [填写应用介绍]
  ├── 应用图标: [上传 1024x1024 图标]
  ├── 应用截图: [上传至少3张截图]
  └── 应用分类: [选择合适的分类]

→ 隐私政策
  └── [填写隐私政策链接]
```

#### 6.2 提交审核

```
→ 保存草稿
→ 提交审核
→ 等待审核结果（通常1-3个工作日）
```

---

## 🔍 常见问题

### Q1: Profile 文件非法（错误码993）

**原因**：
- ❌ 使用了 debugKey 调试签名
- ❌ Profile 文件是 IDE 自动生成的
- ❌ Profile 文件与应用包名不匹配
- ❌ Profile 文件已过期

**解决**：
- ✅ 使用正式的发布 Profile
- ✅ 确保包名完全一致
- ✅ 重新下载最新的 Profile

### Q2: 证书指纹不匹配

**原因**：
- Profile 文件中的证书与实际签名证书不匹配

**解决**：
```
1. 重新生成 CSR 和证书
2. 使用新证书创建新的 Profile
3. 确保三个文件对应：
   - .p12 密钥库
   - .cer 证书
   - .p7b Profile
```

### Q3: 包名不匹配

**原因**：
- AppScope/app.json5 中的 bundleName 与 Profile 中的不一致

**解决**：
```
确保以下位置的包名完全一致：
1. AppScope/app.json5 → bundleName
2. Profile 配置时填写的 Bundle ID
3. 开发者后台应用信息中的包名
```

### Q4: 密钥别名错误

**原因**：
- build-profile.json5 中的 keyAlias 与密钥库中的不一致

**解决**：
```bash
# 查看密钥库中的别名
keytool -list -v -keystore signature/release.p12 -storepass [密码]

# 在构建配置中使用正确的别名
"keyAlias": "release_key"  # 使用实际的别名
```

---

## 📋 检查清单

上传前请确认：

- [ ] 已在开发者后台创建应用
- [ ] 包名为 `com.mtx.take.code`
- [ ] 已生成正式的密钥库（.p12）
- [ ] 已从开发者后台下载证书（.cer）
- [ ] 已下载**发布类型**的 Profile（.p7b）
- [ ] build-profile.json5 配置正确
- [ ] keyAlias 不是 "debugKey"
- [ ] 已重新构建应用
- [ ] HAP 包已正确签名
- [ ] 应用信息和截图已准备完整

---

## 🎯 签名文件结构

正确的签名文件结构：

```
signature/
├── release.p12              # 密钥库文件（自己生成）
├── release.csr              # 证书签名请求（生成后可删除）
├── release.cer              # 证书文件（从后台下载）
├── release.p7b              # Profile文件（从后台下载，发布类型）
└── README.md                # 签名说明
```

**重要提示**：
- ✅ release.p12 - 自己生成，妥善保管
- ✅ release.cer - 从开发者后台下载
- ✅ release.p7b - 从开发者后台下载，**必须是发布类型**
- ❌ 不要使用 `.ohos/config/` 下的文件！

---

## 🔐 安全提示

### 密钥库密码要求
- 长度至少 32 位
- 包含大小写字母、数字、特殊字符
- 妥善保管，丢失无法找回

### 文件保密
```
signature/release.p12  ← 严格保密！
signature/release.cer  ← 可以公开
signature/release.p7b  ← 可以公开
```

### Git 忽略
确保 `.gitignore` 包含：
```
*.p12
*.keystore
```

---

## 📞 技术支持

如果仍有问题：

1. **华为开发者论坛**
   - https://developer.huawei.com/consumer/cn/forum/

2. **技术支持**
   - https://developer.huawei.com/consumer/cn/support/

3. **常见问题**
   - 搜索错误码：993
   - 查看官方文档

---

## ✅ 成功标志

当你看到以下信息时，说明配置正确：

```
✓ 构建成功
✓ HAP 包已签名
✓ 文件名: entry-default-signed.hap
✓ 上传成功
✓ 审核中...
```

---

**创建时间**：2025-10-25  
**适用版本**：HarmonyOS NEXT API 11+  
**状态**：✅ 完整指南

