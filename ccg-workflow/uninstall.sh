#!/bin/bash
# CCG Workflow 卸载脚本
# 移除已安装的斜杠命令

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

COMMANDS_DIR="$HOME/.claude/commands/ccg"

echo -e "${BLUE}╔════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     CCG Workflow 卸载程序                  ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════╝${NC}"
echo ""

# 检查命令目录是否存在
if [ ! -d "$COMMANDS_DIR" ]; then
    echo -e "${YELLOW}CCG Workflow 命令未安装。${NC}"
    exit 0
fi

# 统计要移除的命令
REMOVED_COUNT=0
KEPT_COUNT=0

echo -e "${BLUE}移除命令...${NC}"

for cmd in "$COMMANDS_DIR"/*.md; do
    if [ -f "$cmd" ]; then
        CMD_NAME=$(basename "$cmd")

        # 只移除符号链接（我们安装的）
        if [ -L "$cmd" ]; then
            rm "$cmd"
            echo -e "  ${GREEN}✓${NC} 已移除 $CMD_NAME"
            REMOVED_COUNT=$((REMOVED_COUNT + 1))
        else
            echo -e "  ${YELLOW}保留${NC} $CMD_NAME (非链接文件)"
            KEPT_COUNT=$((KEPT_COUNT + 1))
        fi
    fi
done

# 如果目录为空，删除目录
if [ -z "$(ls -A "$COMMANDS_DIR" 2>/dev/null)" ]; then
    rmdir "$COMMANDS_DIR"
    echo -e "${BLUE}已删除空目录: $COMMANDS_DIR${NC}"
fi

echo ""
echo -e "${GREEN}════════════════════════════════════════${NC}"
echo -e "${GREEN}卸载完成!${NC}"
echo -e "${GREEN}════════════════════════════════════════${NC}"
echo ""
echo -e "已移除: ${GREEN}$REMOVED_COUNT${NC} 个命令"
if [ $KEPT_COUNT -gt 0 ]; then
    echo -e "已保留: ${YELLOW}$KEPT_COUNT${NC} 个自定义命令"
fi
