#!/usr/bin/env bash
# 清除本机《荒野逐羊》的本地数据：开团库、我的模组、自动备份与界面偏好。
#
# 只影响这台 Mac 上的数据；iPad / 模拟器需要另删 App。删除前请先退出 App。
# 默认先列出要删的内容并等待确认；加 --yes 直接删除。

set -euo pipefail

BASE="$HOME/Library/Application Support"
APP_DIR="$BASE/SheepChase"
PREFS_PLIST="$HOME/Library/Preferences/local.sheepchase.mac.plist"

targets=()
add_target() {
    local path="$1"
    if [ -e "$path" ]; then
        targets+=("$path")
    fi
}

add_target "$APP_DIR"
add_target "$BASE/default.store"
add_target "$BASE/default.store-wal"
add_target "$BASE/default.store-shm"
add_target "$BASE/MyAdventureTemplates.json"
add_target "$PREFS_PLIST"

echo "《荒野逐羊》本地数据位置："
if [ ${#targets[@]} -eq 0 ]; then
    echo "  （没有找到任何本地数据）"
    exit 0
fi
for path in "${targets[@]}"; do
    printf '  %s\n' "$path"
done

if [ "${1:-}" != "--yes" ]; then
    echo
    read -r -p "确认删除以上数据？此操作不可撤销 [y/N] " answer
    case "$answer" in
        y|Y|yes|YES) ;;
        *) echo "已取消"; exit 0 ;;
    esac
fi

for path in "${targets[@]}"; do
    rm -rf "$path"
    echo "已删除：$path"
done

if [ -f "$PREFS_PLIST" ]; then
    defaults delete local.sheepchase.mac >/dev/null 2>&1 || true
fi

echo "完成。下次启动 App 会从空开团库开始；Debug 构建可用 -demoRun 重新写入示例开团。"
