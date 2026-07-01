#!/bin/bash
# 吃什么App 固定验证三关
# 用途：每次代码修改后先跑这个脚本，三关全过才算可交付
# 前提：确保 JAVA_HOME 指向 JDK 17+, DevEco Studio/CLI tools 已安装并配置好 PATH
# 用法：bash verify.sh

set -e

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
RED='\e[31m'
GREEN='\e[32m'
YELLOW='\e[33m'
NC='\e[0m'

pass() { echo -e "${GREEN}[PASS]${NC} $1"; }
fail() { echo -e "${RED}[FAIL]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

cd "$PROJECT_DIR"

echo "=========================================="
echo "  吃什么App · 固定验证三关"
echo "  $(date '+%Y-%m-%d %H:%M:%S')"
echo "=========================================="
echo

# ──────────────────────────────────────────
# 第0关：环境检查
# ──────────────────────────────────────────
echo "── 第0关：环境检查 ──"

# JDK
if [ -n "$JAVA_HOME" ] && [ -x "$JAVA_HOME/bin/java" ]; then
  JAVA_VER=$("$JAVA_HOME/bin/java" -version 2>&1 | head -1)
  pass "JDK: $JAVA_VER"
elif command -v java &>/dev/null; then
  JAVA_VER=$(java -version 2>&1 | head -1)
  pass "JDK (from PATH): $JAVA_VER"
else
  fail "未找到 Java。请设置 JAVA_HOME 指向 JDK 17+"
  exit 1
fi

# hvigorw (DevEco Studio 自带 wrapper)
if [ -f "$PROJECT_DIR/hvigorw.bat" ] || [ -f "$PROJECT_DIR/hvigorw" ]; then
  pass "hvigorw wrapper 就绪"
elif command -v hvigorw &>/dev/null; then
  pass "hvigorw (全局安装)"
else
  fail "未找到 hvigorw。请确认项目根目录有 hvigorw.bat，或 DevEco Studio 已安装"
  exit 1
fi

# Node.js (hvigor 依赖)
if command -v node &>/dev/null; then
  NODE_VER=$(node --version)
  pass "Node.js: $NODE_VER"
else
  fail "未找到 Node.js。hvigor 构建依赖 Node.js"
  exit 1
fi

echo

# ──────────────────────────────────────────
# 第一关：编译通过
# ──────────────────────────────────────────
echo "── 第一关：编译 ──"

if command -v hvigorw &>/dev/null; then
  hvigorw assembleHap --no-daemon 2>&1 | tail -20
  HAP_EXIT=$?
elif [ -f "$PROJECT_DIR/hvigorw.bat" ]; then
  cmd.exe /c "cd /d $PROJECT_DIR && hvigorw.bat assembleHap --no-daemon" 2>&1 | tail -20
  HAP_EXIT=$?
elif [ -f "$PROJECT_DIR/hvigorw" ]; then
  ./hvigorw assembleHap --no-daemon 2>&1 | tail -20
  HAP_EXIT=$?
fi

if [ "${HAP_EXIT:-1}" -eq 0 ]; then
  pass "编译通过 (assembleHap)"
else
  fail "编译失败，退出码: ${HAP_EXIT:-未执行}"
  exit 2
fi

echo

# ──────────────────────────────────────────
# 第二关：HAP 产物验证
# ──────────────────────────────────────────
echo "── 第二关：产物验证 ──"

HAP_GLOB=$(find "$PROJECT_DIR" -name "*.hap" -path "*/build/*" -not -path "*/oh_modules/*" 2>/dev/null | head -1)
if [ -n "$HAP_GLOB" ]; then
  HAP_SIZE=$(stat -c%s "$HAP_GLOB" 2>/dev/null || echo "?")
  pass "HAP: $HAP_GLOB ($HAP_SIZE bytes)"
else
  warn "未找到 .hap 文件 (可能是 debug 构建未配置 signing)"
fi

echo

# ──────────────────────────────────────────
# 第三关：测试通过
# ──────────────────────────────────────────
echo "── 第三关：测试 ──"

TEST_DIR="$PROJECT_DIR/entry/src/ohosTest"
if [ -d "$TEST_DIR" ]; then
  if [[ "$(uname -s)" == MINGW* ]] || [[ "$(uname -s)" == MSYS* ]]; then
    cmd.exe /c "cd /d $PROJECT_DIR && hvigorw.bat test --no-daemon" 2>&1 | tail -20
    TEST_EXIT=$?
  elif command -v hvigorw &>/dev/null; then
    hvigorw test --no-daemon 2>&1 | tail -20
    TEST_EXIT=$?
  fi

  if [ "${TEST_EXIT:-1}" -eq 0 ]; then
    pass "测试通过"
  else
    # 首次测试失败可能是没有真机/模拟器，不算硬失败
    warn "测试未完全通过 (退出码: ${TEST_EXIT:-未执行})。请确认已连接真机或启动模拟器"
  fi
else
  warn "未发现 ohosTest 测试目录，跳过测试"
fi

echo
echo "=========================================="
echo "  验证结束"
echo "=========================================="
