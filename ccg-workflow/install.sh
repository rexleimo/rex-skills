#!/bin/bash
# CCG Workflow 安装脚本
# 将斜杠命令安装到 Claude Code 命令目录

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 获取脚本所在目录（技能根目录）
SKILL_DIR="$(cd "$(dirname "$0")" && pwd)"
COMMANDS_SRC_DIR="$SKILL_DIR/commands"
COMMANDS_DEST_DIR="$HOME/.claude/commands/ccg"
NAMESPACE="ccg"

echo -e "${BLUE}╔════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     CCG Workflow 安装程序                  ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════╝${NC}"
echo ""

# 检查命令源目录是否存在
if [ ! -d "$COMMANDS_SRC_DIR" ]; then
    echo -e "${RED}错误: 找不到命令目录: $COMMANDS_SRC_DIR${NC}"
    exit 1
fi

# 统计命令数量
CMD_COUNT=$(find "$COMMANDS_SRC_DIR" -name "*.md" -type f | wc -l | tr -d ' ')
echo -e "${YELLOW}发现 $CMD_COUNT 个命令定义${NC}"

# 创建目标目录
echo -e "${BLUE}创建命令目录: $COMMANDS_DEST_DIR${NC}"
mkdir -p "$COMMANDS_DEST_DIR"

# 链接命令文件
echo -e "${BLUE}安装命令...${NC}"
INSTALLED_COUNT=0
SKIPPED_COUNT=0

for cmd in "$COMMANDS_SRC_DIR"/*.md; do
    if [ -f "$cmd" ]; then
        CMD_NAME=$(basename "$cmd")
        DEST_FILE="$COMMANDS_DEST_DIR/$CMD_NAME"

        # 检查是否已存在且不是符号链接
        if [ -e "$DEST_FILE" ] && [ ! -L "$DEST_FILE" ]; then
            echo -e "  ${YELLOW}跳过${NC} $CMD_NAME (已存在非链接文件)"
            SKIPPED_COUNT=$((SKIPPED_COUNT + 1))
            continue
        fi

        # 创建符号链接
        ln -sf "$cmd" "$DEST_FILE"
        echo -e "  ${GREEN}✓${NC} $CMD_NAME → /$NAMESPACE:$(echo "$CMD_NAME" | sed 's/\.md$//')"
        INSTALLED_COUNT=$((INSTALLED_COUNT + 1))
    fi
done

echo ""
echo -e "${GREEN}════════════════════════════════════════${NC}"
echo -e "${GREEN}安装完成!${NC}"
echo -e "${GREEN}════════════════════════════════════════${NC}"
echo ""
echo -e "已安装: ${GREEN}$INSTALLED_COUNT${NC} 个命令"
if [ $SKIPPED_COUNT -gt 0 ]; then
    echo -e "已跳过: ${YELLOW}$SKIPPED_COUNT${NC} 个命令"
fi
echo ""
echo -e "命令目录: ${BLUE}$COMMANDS_DEST_DIR${NC}"
echo ""
echo -e "可用命令:"
echo -e "  ${BLUE}/ccg:propose${NC}   - 从想法到计划"
echo -e "  ${BLUE}/ccg:explore${NC}   - 多模型头脑风暴"
echo -e "  ${BLUE}/ccg:new${NC}       - 启动新变更"
echo -e "  ${BLUE}/ccg:continue${NC}  - 执行下一步"
echo -e "  ${BLUE}/ccg:ff${NC}        - 快进到计划"
echo -e "  ${BLUE}/ccg:apply${NC}     - 实施计划"
echo -e "  ${BLUE}/ccg:verify${NC}    - 多模型代码审查"
echo -e "  ${BLUE}/ccg:archive${NC}   - 完成并提交"
echo -e "  ${BLUE}/ccg:status${NC}    - 查看工作流程状态"
echo -e "  ${BLUE}/ccg:config${NC}    - 管理配置"
echo -e "  ${BLUE}/ccg:onboard${NC}   - 交互式教程"
echo ""
echo -e "${YELLOW}提示: 运行 /ccg:onboard 开始交互式教程${NC}"
