#!/usr/bin/env pwsh
# 快递取件码管理 - 安装修复脚本
# 解决 Error Code:10104001 问题

Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "  安装问题诊断和修复工具" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

# 应用信息（从 AppScope/app.json5 读取）
$bundleName = "com.mtx.take.code"
$abilityName = "EntryAbility"
$hapFile = "entry\build\default\outputs\default\entry-default-unsigned.hap"

Write-Host "应用信息:" -ForegroundColor Yellow
Write-Host "  Bundle Name: $bundleName"
Write-Host "  Ability Name: $abilityName"
Write-Host ""

# 1. 查找 hdc 命令
Write-Host "[步骤 1] 查找 hdc 工具..." -ForegroundColor Yellow

$hdcPaths = @(
    "$env:LOCALAPPDATA\Huawei\Sdk\openharmony\*\toolchains\hdc.exe",
    "$env:USERPROFILE\Huawei\Sdk\openharmony\*\toolchains\hdc.exe",
    "C:\Program Files\Huawei\DevEco Studio\sdk\*\toolchains\hdc.exe"
)

$hdcPath = $null
foreach ($pattern in $hdcPaths) {
    $found = Get-ChildItem -Path $pattern -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($found) {
        $hdcPath = $found.FullName
        break
    }
}

if ($hdcPath) {
    Write-Host "✓ 找到 hdc: $hdcPath" -ForegroundColor Green
    $hdc = $hdcPath
} else {
    Write-Host "✗ 未找到 hdc 工具" -ForegroundColor Red
    Write-Host ""
    Write-Host "解决方案:" -ForegroundColor Yellow
    Write-Host "1. 确保已安装 DevEco Studio" -ForegroundColor White
    Write-Host "2. 在 DevEco Studio 中安装 HarmonyOS SDK" -ForegroundColor White
    Write-Host "3. 或者使用 DevEco Studio 直接运行项目（推荐）" -ForegroundColor Green
    Write-Host ""
    Write-Host "快速操作：在 DevEco Studio 中按 Shift + F10 运行项目" -ForegroundColor Cyan
    Write-Host ""
    pause
    exit 1
}

Write-Host ""

# 2. 检查设备连接
Write-Host "[步骤 2] 检查设备连接..." -ForegroundColor Yellow

$devices = & $hdc list targets 2>&1
if ($LASTEXITCODE -ne 0 -or $devices -match "empty") {
    Write-Host "✗ 未检测到设备" -ForegroundColor Red
    Write-Host ""
    Write-Host "请确保:" -ForegroundColor Yellow
    Write-Host "  1. 设备已通过 USB 连接到电脑" -ForegroundColor White
    Write-Host "  2. 设备已开启开发者模式" -ForegroundColor White
    Write-Host "  3. 设备已开启 USB 调试" -ForegroundColor White
    Write-Host "  4. 或者启动了 HarmonyOS 模拟器" -ForegroundColor White
    Write-Host ""
    pause
    exit 1
}

Write-Host "✓ 已连接设备:" -ForegroundColor Green
Write-Host $devices
Write-Host ""

# 3. 检查 HAP 文件
Write-Host "[步骤 3] 检查 HAP 安装包..." -ForegroundColor Yellow

if (-not (Test-Path $hapFile)) {
    Write-Host "✗ HAP 文件不存在: $hapFile" -ForegroundColor Red
    Write-Host ""
    Write-Host "解决方案:" -ForegroundColor Yellow
    Write-Host "1. 在 DevEco Studio 中构建项目:" -ForegroundColor White
    Write-Host "   Build → Build Hap(s) 或按 Ctrl + F9" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "2. 或使用命令行构建:" -ForegroundColor White
    Write-Host "   hvigorw assembleHap --mode module -p module=entry" -ForegroundColor Cyan
    Write-Host ""
    pause
    exit 1
}

$hapInfo = Get-Item $hapFile
$sizeKB = [math]::Round($hapInfo.Length / 1KB, 2)
Write-Host "✓ HAP 文件存在" -ForegroundColor Green
Write-Host "  文件: $($hapInfo.Name)"
Write-Host "  大小: $sizeKB KB"
Write-Host "  时间: $($hapInfo.LastWriteTime)"
Write-Host ""

# 4. 检查应用是否已安装
Write-Host "[步骤 4] 检查应用安装状态..." -ForegroundColor Yellow

$installed = & $hdc shell bm dump -a 2>&1 | Select-String $bundleName
if ($installed) {
    Write-Host "✓ 应用已安装（旧版本）" -ForegroundColor Yellow
    Write-Host ""
    
    # 5. 卸载旧版本
    Write-Host "[步骤 5] 卸载旧版本..." -ForegroundColor Yellow
    & $hdc uninstall $bundleName 2>&1 | Out-Null
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ 旧版本已卸载" -ForegroundColor Green
    } else {
        Write-Host "✗ 卸载失败，尝试继续安装..." -ForegroundColor Yellow
    }
    Write-Host ""
} else {
    Write-Host "✓ 应用未安装（全新安装）" -ForegroundColor Green
    Write-Host ""
}

# 6. 安装新版本
Write-Host "[步骤 6] 安装应用..." -ForegroundColor Yellow

$installOutput = & $hdc install $hapFile 2>&1
if ($LASTEXITCODE -eq 0 -or $installOutput -match "successfully") {
    Write-Host "✓ 应用安装成功！" -ForegroundColor Green
    Write-Host ""
} else {
    Write-Host "✗ 应用安装失败" -ForegroundColor Red
    Write-Host ""
    Write-Host "错误信息:" -ForegroundColor Yellow
    Write-Host $installOutput
    Write-Host ""
    Write-Host "建议操作:" -ForegroundColor Yellow
    Write-Host "1. 使用 DevEco Studio 直接运行（推荐）" -ForegroundColor Cyan
    Write-Host "   打开项目 → 点击 Run 按钮（Shift + F10）" -ForegroundColor White
    Write-Host ""
    Write-Host "2. 检查签名配置" -ForegroundColor White
    Write-Host "   File → Project Structure → Signing Configs" -ForegroundColor Cyan
    Write-Host "   勾选 'Automatically generate signature'" -ForegroundColor White
    Write-Host ""
    pause
    exit 1
}

# 7. 启动应用
Write-Host "[步骤 7] 启动应用..." -ForegroundColor Yellow

$startCmd = "aa start -a $abilityName -b $bundleName"
$startOutput = & $hdc shell $startCmd 2>&1

if ($LASTEXITCODE -eq 0 -or $startOutput -match "start ability successfully") {
    Write-Host "✓ 应用启动成功！" -ForegroundColor Green
    Write-Host ""
    Write-Host "=====================================" -ForegroundColor Green
    Write-Host "  ✓ 所有步骤完成！" -ForegroundColor Green
    Write-Host "=====================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "应用应该已经在设备上运行了。" -ForegroundColor White
    Write-Host ""
} else {
    Write-Host "✗ 应用启动失败" -ForegroundColor Red
    Write-Host ""
    Write-Host "错误信息:" -ForegroundColor Yellow
    Write-Host $startOutput
    Write-Host ""
    Write-Host "但是应用已经安装成功，你可以：" -ForegroundColor Yellow
    Write-Host "  1. 在设备桌面找到应用图标，手动点击启动" -ForegroundColor White
    Write-Host "  2. 或在 DevEco Studio 中再次点击 Run 按钮" -ForegroundColor White
    Write-Host ""
}

# 8. 显示诊断信息
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "  诊断信息" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Bundle Name: $bundleName" -ForegroundColor White
Write-Host "Ability Name: $abilityName" -ForegroundColor White
Write-Host "HAP 文件: $hapFile" -ForegroundColor White
Write-Host ""
Write-Host "正确的启动命令:" -ForegroundColor Yellow
Write-Host "  hdc shell aa start -a EntryAbility -b com.take.code" -ForegroundColor Cyan
Write-Host ""
Write-Host "查看应用日志:" -ForegroundColor Yellow
Write-Host "  hdc hilog | findstr PickCode" -ForegroundColor Cyan
Write-Host ""

pause

