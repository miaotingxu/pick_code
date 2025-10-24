# 签名文件目录

这个目录用于存放应用签名相关的文件。

## 文件说明

- `*.p12` - 密钥库文件（私钥）
- `*.cer` - 证书文件
- `*.p7b` - Profile 配置文件

## ⚠️ 重要提示

**请勿将此目录中的以下文件提交到版本控制系统：**
- .p12 密钥文件
- .cer 证书文件
- .p7b Profile文件

这些文件包含敏感信息，泄露可能导致安全问题。

## 如何生成签名文件

请参考项目根目录下的 `签名配置指南.md` 文件。

### 快速开始

**最简单的方式（推荐）：**

1. 打开 DevEco Studio
2. `File` → `Project Structure` → `Signing Configs`
3. 勾选 `Automatically generate signature`
4. 点击 `OK`

DevEco Studio 会自动生成调试签名，无需手动配置！



