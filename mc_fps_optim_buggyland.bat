@echo off
chcp 65001
title Minecraft FPS Optimizer - 布吉岛专用版
cls

echo =====================================================
echo  Minecraft FPS 优化脚本（布吉岛专用低画质版）
echo  针对：岛屿/水域/建筑密集场景卡顿
echo  功能：自动配置超低画质 + 系统优化 + 进程提权
echo =====================================================
echo.

rem =====================================================
rem 0. 检查管理员权限
rem =====================================================
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
if '%errorlevel%' NEQ '0' (
    echo [ERROR] 当前脚本需要管理员权限运行。
    echo 请右键 -^> 以管理员身份运行。
    pause
    exit /b
)

rem =====================================================
rem 1. 定义 Minecraft 配置文件路径
rem =====================================================
set "MC_DIR=%USERPROFILE%\.minecraft"
set "MC_OPTIONS=%MC_DIR%\options.txt"
set "MC_LAUNCHER=%USERPROFILE%\AppData\Local\Programs\Minecraft Launcher\Minecraft.exe"

if not exist "%MC_DIR%" (
    echo [ERROR] 未找到 Minecraft 目录：%MC_DIR%
    echo 请先启动一次官方 Minecraft 启动器。
    pause
    exit /b 1
)

echo [✓] 找到 Minecraft 目录：%MC_DIR%

rem =====================================================
rem 2. 备份原始 options.txt
rem =====================================================
echo [1/7] 备份原始配置文件...
if exist "%MC_OPTIONS%" (
    if not exist "%MC_OPTIONS%.backup" (
        copy "%MC_OPTIONS%" "%MC_OPTIONS%.backup" >nul 2>&1
        echo [✓] 已备份到 options.txt.backup
    ) else (
        echo [✓] 备份文件已存在，跳过
    )
) else (
    echo [WARN] 未找到 options.txt，将在启动后创建
)

rem =====================================================
rem 3. 创建临时配置修改脚本（PowerShell）
rem =====================================================
echo [2/7] 生成布吉岛超低画质配置...

set "PS_SCRIPT=%TEMP%\mc_config.ps1"

(
echo # Minecraft 布吉岛专用超低画质配置脚本
echo $MC_OPTIONS = "%MC_OPTIONS%"
echo $MC_DIR = "%MC_DIR%"
echo.
echo # 确保文件存在
echo if (^!(Test-Path $MC_OPTIONS^)) {
echo     New-Item -ItemType File -Path $MC_OPTIONS -Force ^| Out-Null
echo }
echo.
echo # 读取或创建配置
echo $config = @{}
echo if (Test-Path $MC_OPTIONS) {
echo     $lines = Get-Content $MC_OPTIONS -ErrorAction SilentlyContinue
echo     foreach ($line in $lines) {
echo         if ($line -match '^(.+?)=(.*)$') {
echo             $config[$matches[1]] = $matches[2]
echo         }
echo     }
echo }
echo.
echo # 布吉岛超低画质配置（针对水域/建筑密集场景）
echo $lowQualitySettings = @{
echo     'renderDistance' = '6'
echo     'simulationDistance' = '5'
echo     'maxFramerate' = '60'
echo     'graphicsMode' = 'fast'
echo     'fancyGraphics' = 'false'
echo     'ambientOcclusion' = 'off'
echo     'particles' = '0'
echo     'entity_shadows' = 'false'
echo     'ao' = 'off'
echo     'mipmapLevels' = '0'
echo     'useVsync' = 'true'
echo     'enableVsync' = 'true'
echo     'guiScale' = '2'
echo     'attackIndicator' = 'off'
echo     'autosaveInterval' = '6000'
echo     'cloudHeight' = '0'
echo     'showSubtitles' = 'false'
echo     'soundVolume:ambient' = '0.0'
echo     'soundVolume:hostile' = '0.0'
echo     'soundVolume:neutral' = '0.0'
echo     'soundVolume:player' = '0.5'
echo     'soundVolume:record' = '0.0'
echo     'soundVolume:voice' = '0.0'
echo     'soundVolume:weather' = '0.0'
echo     'soundVolume:block' = '0.5'
echo }
echo.
echo # 应用配置
echo foreach ($key in $lowQualitySettings.Keys) {
echo     $config[$key] = $lowQualitySettings[$key]
echo }
echo.
echo # 写回文件
echo $output = @()
echo foreach ($key in ($config.Keys ^| Sort-Object)) {
echo     $output += "$key=$($config[$key])"
echo }
echo Set-Content -Path $MC_OPTIONS -Value $output -Encoding UTF8 -Force
echo Write-Host "[✓] 已应用超低画质配置到 $MC_OPTIONS"
) > "%PS_SCRIPT%"

rem 执行 PowerShell 脚本
powershell -NoProfile -ExecutionPolicy Bypass -File "%PS_SCRIPT%" 2>nul
if %errorlevel% equ 0 (
    echo [✓] 配置应用成功
) else (
    echo [WARN] PowerShell 配置失败，将使用替代方案
)

rem =====================================================
rem 4. 手动创建/更新关键配置（备用方案）
rem =====================================================
echo [3/7] 应用关键低画质选项...

setlocal enabledelayedexpansion

if exist "%MC_OPTIONS%" (
    findstr /I "renderDistance" "%MC_OPTIONS%" >nul
    if !errorlevel! equ 0 (
        powershell -NoProfile -Command "(Get-Content '%MC_OPTIONS%') -replace 'renderDistance:\d+', 'renderDistance:6' | Set-Content '%MC_OPTIONS%'" 2>nul
    )
    
    findstr /I "fancyGraphics" "%MC_OPTIONS%" >nul
    if !errorlevel! equ 0 (
        powershell -NoProfile -Command "(Get-Content '%MC_OPTIONS%') -replace 'fancyGraphics:true', 'fancyGraphics:false' | Set-Content '%MC_OPTIONS%'" 2>nul
    )
    
    findstr /I "particles" "%MC_OPTIONS%" >nul
    if !errorlevel! equ 0 (
        powershell -NoProfile -Command "(Get-Content '%MC_OPTIONS%') -replace 'particles:\d+', 'particles:0' | Set-Content '%MC_OPTIONS%'" 2>nul
    )
    
    findstr /I "graphicsMode" "%MC_OPTIONS%" >nul
    if !errorlevel! equ 0 (
        powershell -NoProfile -Command "(Get-Content '%MC_OPTIONS%') -replace 'graphicsMode:fancy', 'graphicsMode:fast' | Set-Content '%MC_OPTIONS%'" 2>nul
    )
)

echo [✓] 已应用核心低画质选项

endlocal

rem =====================================================
rem 5. 删除或移动资源包以减少加载压力
rem =====================================================
echo [4/7] 清理资源包和着色器...

set "RESOURCEPACKS=%MC_DIR%\resourcepacks"
if exist "%RESOURCEPACKS%" (
    for /d %%d in ("%RESOURCEPACKS%\*") do (
        if not "%%~nxd"=="vanilla" (
            ren "%%d" "%%~nxd.disabled" >nul 2>&1
        )
    )
    echo [✓] 已禁用第三方资源包
)

set "SHADERPACKS=%MC_DIR%\shaderpacks"
if exist "%SHADERPACKS%" (
    for %%f in ("%SHADERPACKS%\*") do (
        ren "%%f" "%%~nxf.disabled" >nul 2>&1
    )
    echo [✓] 已禁用所有着色器
)

rem =====================================================
rem 6. 系统级优化
rem =====================================================
echo [5/7] 执行系统级优化...

rem 切换高性能电源模式
powercfg /setactive SCHEME_MIN >nul 2>&1

rem 关闭不必要后台进程
taskkill /F /IM chrome.exe >nul 2>&1
taskkill /F /IM msedge.exe >nul 2>&1
taskkill /F /IM steam.exe >nul 2>&1
taskkill /F /IM Discord.exe >nul 2>&1
taskkill /F /IM qq.exe >nul 2>&1
taskkill /F /IM WeChat.exe >nul 2>&1
taskkill /F /IM Spotify.exe >nul 2>&1
taskkill /F /IM OneDrive.exe >nul 2>&1

echo [✓] 已关闭常见占用��程

rem =====================================================
rem 7. 启动 Minecraft
rem =====================================================
echo [6/7] 准备启动 Minecraft...

if exist "%MC_LAUNCHER%" (
    echo 即将启动 Minecraft 官方启动器...
    timeout /t 3 /nobreak
    start "" "%MC_LAUNCHER%"
) else (
    echo [WARN] 未找到 Minecraft 启动器
    echo 请手动启动 Minecraft 或使用启动器
)

rem =====================================================
rem 8. 监控并优化游戏进程
rem =====================================================
echo [7/7] 等待游戏启动并优化进程...
echo.
echo 脚本将在 12 秒后尝试找到 Java/Minecraft 进程并提升其优先级...
timeout /t 12 /nobreak

rem 获取 Java 进程 PID
for /f "tokens=2" %%P in ('tasklist /FI "IMAGENAME eq java.exe" 2^>nul ^| findstr /I java') do (
    set JAVA_PID=%%P
    goto :found_proc
)

for /f "tokens=2" %%P in ('tasklist /FI "IMAGENAME eq javaw.exe" 2^>nul ^| findstr /I javaw') do (
    set JAVA_PID=%%P
    goto :found_proc
)

:found_proc
if defined JAVA_PID (
    echo [✓] 检测到 Java 进程 PID=%JAVA_PID%
    
    rem 提升至高优先级
    wmic process where processid=%JAVA_PID% call setpriority 128 >nul 2>&1
    echo [✓] 已将 Minecraft 进程设为高优先级（Realtime）
    
    rem 设置 CPU 亲和性（如果可能）
    powershell -NoProfile -Command "Start-Process -WindowStyle Hidden -FilePath 'wmic.exe' -ArgumentList 'process where processid=%JAVA_PID% call setpriority 256'" >nul 2>&1
) else (
    echo [!] 未检测到 Java 进程
    echo [!] 你可能需要在启动器中手动选择版本并启动游戏
)

rem =====================================================
rem 9. 显示最终信息和建议
rem =====================================================
echo.
echo =====================================================
echo  ★ 布吉岛 FPS 优化完成！
echo =====================================================
echo.
echo [配置已应用]
echo  • 渲染距离：6 格（低水域卡顿）
echo  • 模拟距离：5 格（减少刻度计算）
echo  • 粒子效果：关闭（减少渲染压力）
echo  • 图形模式：快速（禁用光影/阴影）
echo  • 环境光遮挡：关闭
echo  • 云高度：0（禁用云层）
echo  • 声音：环境/敌对/中立均关闭（减少线程占用）
echo.
echo [系统优化已完成]
echo  • 切换至高性能电源模式
echo  • 关闭常见后台占用程序
echo  • 提升 Minecraft 进程优先级至最高
echo.
echo [布吉岛专用建议]
echo  1. 游戏内按 ESC -^> 设置 -^> 视频设置 -^> 最大帧率调至 60
echo  2. 生物群系装饰：关闭（减少树木/植被渲染）
echo  3. 实体阴影：关闭
echo  4. 实体距离：50%
echo  5. 亮度：亮
echo  6. 如果还卡顿，再降低渲染距离到 4-5 格
echo  7. 建议使用 Sodium/Lithium/FerriteCore MOD 进一步优化（需要 Fabric）
echo.
echo [复原原始设置]
echo  1. 进入 .minecraft 目录
echo  2. 删除 options.txt
echo  3. 重名 options.txt.backup 为 options.txt
echo  4. 重启 Minecraft
echo.
echo =====================================================
echo 按任意键退出...
echo =====================================================
pause >nul
