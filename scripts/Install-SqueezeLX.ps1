<#
.SYNOPSIS
    Squeeze-LX 一键安装与配置脚本
.DESCRIPTION
    自动通过 Microsoft Store 后端接口下载并静默安装 Squeeze-LX，并放行 LMS 发现的 UDP 端口。
#>

# 要求管理员权限
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "请以管理员身份运行此脚本！"
    exit
}

$AppName = "Squeeze-LX"
$StoreId = "9pbhmtnp9037" # 美区商店 ID

Write-Host "=== 开始安装 $AppName ===" -ForegroundColor Cyan

# 1. 使用 winget 直接从商店后端拉取（即使本地商店搜不到也能装）
Write-Host "正在通过 Winget 获取安装包..." -ForegroundColor Yellow
try {
    winget install --id $StoreId --source msstore --accept-package-agreements --accept-source-agreements
    Write-Host "安装指令执行完毕！" -ForegroundColor Green
} catch {
    Write-Warning "Winget 安装失败，可能需要手动切换美区商店或使用 SourceForge 版本。"
}

# 2. 配置防火墙（放行 LMS 的 UDP 发现广播，确保能自动连上服务器）
Write-Host "正在配置防火墙，允许局域网发现..." -ForegroundColor Yellow
$RuleName = "Lyrion Music Server Discovery"
if (-not (Get-NetFirewallRule -DisplayName $RuleName -ErrorAction SilentlyContinue)) {
    New-NetFirewallRule -DisplayName $RuleName -Direction Inbound -Action Allow -Protocol UDP -LocalPort 3483 -Profile Private
    New-NetFirewallRule -DisplayName "$RuleName (Web)" -Direction Inbound -Action Allow -Protocol TCP -LocalPort 9000,9090 -Profile Private
    Write-Host "防火墙规则已添加。" -ForegroundColor Green
} else {
    Write-Host "防火墙规则已存在，跳过。" -ForegroundColor DarkGray
}

Write-Host "=== 安装完成 ===" -ForegroundColor Cyan
Write-Host "1. 请在开始菜单打开 $AppName"
Write-Host "2. 在设置中，务必把 Player Output Device 选为 [Windows WASAPI]"
Write-Host "3. 勾选 Auto start on log in、Run in background 和 Start minimized"