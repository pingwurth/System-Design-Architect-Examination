#!/bin/sh
# ============================================================================
# 功能说明：扫描 images 目录，找出未被 Markdown 文件引用的图片
#
# 用法：
#   ./picture_not_use.sh [图片目录] [Markdown目录]
#
# 参数说明：
#   图片目录  - 包含图片的目录路径（默认：../教材/系统架构设计师教程/images）
#   Markdown目录 - 包含 .md 文件的目录路径（默认：../教材/系统架构设计师教程）
#
# 示例：
#   ./picture_not_use.sh
#   ./picture_not_use.sh /path/to/images /path/to/docs
#   ./picture_not_use.sh ../images ../chapters
#
# 兼容性说明：
#   - 本脚本遵循 POSIX sh 规范，兼容 bash/dash/zsh 等 shell
#   - 使用 grep -E 替代 grep -P 以兼容 macOS
#   - 使用 awk 替代 bash 数组以兼容 POSIX
# ============================================================================

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# 默认路径配置
DEFAULT_IMAGE_DIR="$SCRIPT_DIR/../../教材/系统架构设计师教程/images"
DEFAULT_MD_DIR="$SCRIPT_DIR/../../教材/系统架构设计师教程"

# 使用命令行参数或默认值
IMAGE_DIR="${1:-$DEFAULT_IMAGE_DIR}"
MD_DIR="${2:-$DEFAULT_MD_DIR}"

# 验证目录是否存在
if [ ! -d "$IMAGE_DIR" ]; then
    echo "错误：图片目录不存在 - $IMAGE_DIR" >&2
    exit 1
fi

if [ ! -d "$MD_DIR" ]; then
    echo "错误：Markdown 目录不存在 - $MD_DIR" >&2
    exit 1
fi

# ============================================================================
# 步骤 1：获取所有图片文件列表
# ============================================================================
# 说明：列出 images 目录下所有图片文件（支持常见图片格式）
# 提取文件名用于后续比对

echo "正在扫描图片目录：$IMAGE_DIR"
echo "正在扫描 Markdown 目录：$MD_DIR"
echo ""

# 获取图片文件总数
TOTAL_IMAGES=$(find "$IMAGE_DIR" -type f \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" -o -name "*.gif" -o -name "*.webp" -o -name "*.svg" \) | wc -l)

if [ "$TOTAL_IMAGES" -eq 0 ]; then
    echo "提示：图片目录中未找到图片文件"
    exit 0
fi

echo "找到 $TOTAL_IMAGES 个图片文件"
echo ""

# ============================================================================
# 步骤 2：从所有 Markdown 文件中提取引用的图片文件名
# ============================================================================
# 说明：使用 grep 扫描所有 .md 文件，提取 ![](../images/xxx.jpg) 中的文件名
# 使用 sed 提取图片文件名部分

echo "正在扫描 Markdown 文件中的图片引用..."

# 创建临时文件存储引用的图片
REFERENCED_IMAGES=$(mktemp)
trap "rm -f $REFERENCED_IMAGES" EXIT

# 扫描所有 .md 文件，提取图片引用
# 支持格式：![](../images/xxx.jpg) 或 ![](images/xxx.jpg)
find "$MD_DIR" -type f -name "*.md" -exec grep -oE '\!\[([^]]*)\]\([^)]*images/([^)]+)\)' {} + 2>/dev/null | \
    sed -E 's/.*images\/([^)]+).*/\1/' | \
    sort -u > "$REFERENCED_IMAGES"

# 获取引用的图片数量
TOTAL_REFERENCED=$(wc -l < "$REFERENCED_IMAGES")

echo "找到 $TOTAL_REFERENCED 个被引用的图片文件"
echo ""

# ============================================================================
# 步骤 3：比较并找出未使用的图片
# ============================================================================
# 说明：遍历所有图片文件，检查是否在引用列表中
# 输出未被引用的图片文件名

echo "正在比较图片使用情况..."
echo ""

# 计数器
UNUSED_COUNT=0

# 创建临时文件存储所有图片文件名
ALL_IMAGES=$(mktemp)
trap "rm -f $REFERENCED_IMAGES $ALL_IMAGES" EXIT

# 获取所有图片文件名
find "$IMAGE_DIR" -type f \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" -o -name "*.gif" -o -name "*.webp" -o -name "*.svg" \) -exec basename {} \; | \
    sort > "$ALL_IMAGES"

# 比较找出未使用的图片
echo "=== 未使用的图片列表 ==="
echo ""

while IFS= read -r image_file; do
    # 检查图片是否在引用列表中
    if ! grep -q "^${image_file}$" "$REFERENCED_IMAGES"; then
        echo "$image_file"
        UNUSED_COUNT=$((UNUSED_COUNT + 1))
    fi
done < "$ALL_IMAGES"

echo ""
echo "=== 统计信息 ==="
echo "图片总数：$TOTAL_IMAGES"
echo "已引用数量：$TOTAL_REFERENCED"
echo "未使用数量：$UNUSED_COUNT"
