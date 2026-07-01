# 吃什么App 固定验证三关 (PowerShell版)
# 用途：每次代码修改后先跑这个脚本，三关全过才算可交付
# 前提：DevEco Studio 已安装，项目根目录存在 hvigorw.bat
# 用法：.\verify.ps1
#
# 如果 PowerShell 不允许运行脚本，先执行：
#   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
# 或直接用：
#   powershell -ExecutionPolicy Bypass -File verify.ps1

$ErrorActionPreference = "Continue"
$ProjectDir = Split-Path -Parent $MyInvocation.MyCommand.Path

function Write-Pass { Write-Host "[PASS] $args" -ForegroundColor Green }
function Write-Fail { Write-Host "[FAIL] $args" -ForegroundColor Red }
function Write-Warn { Write-Host "[WARN] $args" -ForegroundColor Yellow }

Write-Host "=========================================="
Write-Host "  吃什么App · 固定验证三关"
Write-Host "  $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Host "=========================================="
Write-Host ""

# ──────────────────────────────────────────
# 第0关：环境检查
# ──────────────────────────────────────────
Write-Host "── 第0关：环境检查 ──"

# JDK
$javaHome = $env:JAVA_HOME
if (-not $javaHome) {
    $javaHome = "$ProjectDir\.toolchain\jdk\jdk17\jdk-17.0.19+10"
}
$javaExe = Join-Path $javaHome "bin\java.exe"
if (Test-Path $javaExe) {
    $javaVer = & $javaExe -version 2>&1 | Select-Object -First 1
    Write-Pass "JDK: $javaVer"
} else {
    Write-Fail "未找到 Java。请设置 JAVA_HOME 或确认 .toolchain/jdk 路径"
    exit 1
}

# hvigorw
$hvigorw = Join-Path $ProjectDir "hvigorw.bat"
if (Test-Path $hvigorw) {
    Write-Pass "hvigorw.bat 就绪"
} else {
    Write-Fail "未找到 hvigorw.bat。请用 DevEco Studio 打开本项目一次以生成 wrapper"
    Write-Host "  操作：DevEco Studio → Open → 选择本目录 → 等待同步完成"
    exit 1
}

# Node.js
$node = Get-Command node -ErrorAction SilentlyContinue
if ($node) {
    $nodeVer = & node --version
    Write-Pass "Node.js: $nodeVer"
} else {
    Write-Fail "未找到 Node.js。hvigor 构建依赖 Node.js"
    Write-Host "  建议安装：https://nodejs.org/ (LTS 版本即可)"
    exit 1
}

Write-Host ""

# ──────────────────────────────────────────
# 第一关：编译通过
# ──────────────────────────────────────────
Write-Host "── 第一关：编译 ──"

Push-Location $ProjectDir
try {
    $hapResult = cmd /c "hvigorw.bat assembleHap --no-daemon 2>&1"
    if ($LASTEXITCODE -eq 0) {
        Write-Pass "编译通过 (assembleHap)"
    } else {
        Write-Fail "编译失败，退出码: $LASTEXITCODE"
        Write-Host "--- 编译输出 (最后40行) ---"
        $hapResult | Select-Object -Last 40 | ForEach-Object { Write-Host $_ }
        exit 2
    }
} finally {
    Pop-Location
}

Write-Host ""

# ──────────────────────────────────────────
# 第二关：HAP 产物验证
# ──────────────────────────────────────────
Write-Host "── 第二关：产物验证 ──"

$hapFiles = Get-ChildItem -Path $ProjectDir -Recurse -Filter "*.hap" -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -match "\\build\\" -and $_.FullName -notmatch "\\oh_modules\\" }

if ($hapFiles) {
    $hap = $hapFiles | Select-Object -First 1
    Write-Pass "HAP: $($hap.FullName) ($($hap.Length) bytes)"
} else {
    Write-Warn "未找到 .hap 文件 (可能是 debug 构建未配置 signing)"
}

Write-Host ""

# ──────────────────────────────────────────
# 第三关：测试通过
# ──────────────────────────────────────────
Write-Host "── 第三关：测试 ──"

$testDir = Join-Path $ProjectDir "entry\src\ohosTest"
if (Test-Path $testDir) {
    Push-Location $ProjectDir
    try {
        $testResult = cmd /c "hvigorw.bat test --no-daemon 2>&1"
        if ($LASTEXITCODE -eq 0) {
            Write-Pass "测试通过"
        } else {
            Write-Warn "测试未完全通过 (退出码: $LASTEXITCODE)。请确认已连接真机或启动模拟器"
        }
    } finally {
        Pop-Location
    }
} else {
    Write-Warn "未发现 ohosTest 测试目录，跳过测试"
}

Write-Host ""
Write-Host "=========================================="
Write-Host "  验证结束"
Write-Host "=========================================="
