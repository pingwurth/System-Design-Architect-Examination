#!/bin/bash
# ============================================================================
# 脚本名称: split_chapters.sh
# 功能描述: 将 Markdown 文件按二级标题（## ）拆分为独立的章节文件
# 用法: ./split_chapters.sh <markdown文件路径> [起始行号] [结束行号]
# 示例: ./split_chapters.sh ./教材.md 830 17759
# 输出: 在原文件同目录下生成 "第n章-标题.md" 格式的章节文件
# 兼容性: POSIX sh（兼容 Linux / macOS）
# ============================================================================

# ---------- 参数接收 ----------
markdown_file="$1"
start="${2:-830}"    # 默认起始行号
end="${3:-17759}"    # 默认结束行号

# 创建临时文件，用于保存二级标题行号列表
TEMP_FILE="/tmp/lineNum_$(date +%Y%m%d%H%M%S%s)$RANDOM.txt"

# ---------- 第一步：提取二级标题行号 ----------
# 在指定行号范围内（start~end），用 awk 匹配以 "## " 开头的行
# 输出这些行的行号到临时文件
awk -v s="$start" -v e="$end" 'NR>=s && NR<=e && /^## .*/ {print NR}' "$markdown_file" > "$TEMP_FILE"

# 获取 markdown_file 所在目录（输出文件将保存到此目录）
dir=$(dirname "$markdown_file")

# 统计匹配到的二级标题总数
total=$(wc -l < "$TEMP_FILE")
i=0

# ---------- 第二步：逐个处理每个二级标题 ----------
while IFS= read -r line_num; do
    i=$((i + 1))

    # 提取当前标题行的文本（去掉 "## " 前缀）
    heading=$(sed -n "${line_num}p" "$markdown_file" | sed 's/^## //')

    # 从标题中解析章节编号和标题名称
    # 匹配格式：第1章、第12章 等
    chapter=$(echo "$heading" | grep -oE '^第[0-9]+章')
    # 去掉 "第n章" 前缀及可能的分隔符（-、:、：、空格），保留纯标题名
    title=$(echo "$heading" | sed 's/^第[0-9]*章[-:： ]*//')

    # 确定当前章节的内容范围：
    #   起始行 = 当前二级标题所在行
    #   结束行 = 下一个二级标题所在行 - 1（最后一章则用参数 end）
    if [ "$i" -lt "$total" ]; then
        end_line=$(awk "NR==$((i+1)) {print \$1-1}" "$TEMP_FILE")
    else
        end_line=$end
    fi

    # 构建输出文件名
    if [ -n "$chapter" ]; then
        # 标题含 "第n章" 前缀 → 文件名格式：第1章-绪论.md
        filename="${chapter}-${title}.md"
    else
        # 标题不含 "第n章" → 直接用标题作为文件名
        filename="${heading}.md"
    fi

    # ---------- 第三步：提取内容并写入文件 ----------
    sed -n "${line_num},${end_line}p" "$markdown_file" > "$dir/$filename"
    echo "已提取: $dir/$filename (第${line_num}~${end_line}行)"

done < "$TEMP_FILE"

# 清理临时文件
rm -f "$TEMP_FILE"
