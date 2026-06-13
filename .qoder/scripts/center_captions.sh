#!/bin/bash
# ============================================================================
# 脚本名称: center_captions.sh
# 功能描述: 为 Markdown 文件中的图片标题（图n-n）和表格标题（表n-n）添加 <center> 居中包裹
# 用法: ./center_captions.sh <markdown文件路径>
# ============================================================================

# 接收第一个参数作为目标 Markdown 文件路径
markdown_file="$1"

# ---------- 第一部分：图片标题居中 ----------
# 处理逻辑：
#   1. 匹配包含图片引用的行：![任意描述](images/xxx.jpg)
#   2. 从该行开始向下逐行查找，直到找到以 "图n-n" 格式开头的标题行（如：图1-1 系统架构图）
#   3. 将匹配到的图片标题行用 <center>...</center> 包裹，实现居中显示
# sed 说明：
#   - 遇到图片引用行后进入循环，逐行读取（n 命令）
#   - 如果当前行不以 "图数字-数字" 开头，继续向下查找（b label 跳回标签）
#   - 一旦匹配到图标题行，用 <center> 包裹整行内容
sed -i -E '/!\[[^]]*]\(images\/.*jpg\)/{:label; n; /^图[0-9]+-[0-9]+.*/!b label; s/(.*)/<center>\1<\/center>/}' "$markdown_file"

# ---------- 第二部分：表格标题居中 ----------
# 处理逻辑：
#   1. 搜索所有以 "表数字" 开头的行（如：表2-1），记录这些行的行号到临时文件 lineNum.txt
#   2. 逐行读取行号，检查该行之后的 1~2 行内是否包含 <table> 标签
#      - 先检查标题行的下一行（line+1）
#      - 如果下一行没有 <table>，再检查下两行（line+2）
#   3. 如果确认后续存在 <table> 标签，说明该 "表n-n" 行确实是表格标题，将其用 <center> 包裹
#   4. 这样可以避免误将非表格标题的 "表..." 文本居中

TEMP_FILE="/tmp/lineNum_$(date +%Y%m%d%H%M%S%s)$RANDOM.txt"
# 提取所有以 "表数字" 开头的行号，保存到临时文件
sed -n -E '/^表[0-9]+/=' "$markdown_file" > "$TEMP_FILE"

# 遍历每个匹配到的表格标题行号
cat "$TEMP_FILE" | while read line || [ -n "$line" ]; do
    # 检查标题行下一行（line+1）是否包含 <table> 标签
    content=$(sed -n -E "$((line+1)) s/(<table>.*)/\1/p" "$markdown_file")
    # 如果下一行没有 <table>，再检查下两行（line+2）
    if [ -z "$content" ]; then
        content=$(sed -n -E "$((line+2)) s/(<table>.*)/\1/p" "$markdown_file")
    fi
    # 如果在 1~2 行范围内找到了 <table>，则将该标题行居中包裹
    if [ -n "$content" ]; then
         sed -i -E "$line s/(.*)/<center>\1<\/center>/" "$markdown_file"
    fi
done

# 清理临时文件
rm -f "$TEMP_FILE"
