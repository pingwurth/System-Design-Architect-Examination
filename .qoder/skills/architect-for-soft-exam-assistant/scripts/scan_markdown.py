#!/usr/bin/env python3
"""
扫描指定目录下的 Markdown 文件，提取 1-5 级标题和加粗文本。
将结果保存到 /tmp/content.index，每行包含：文件名、行号、类型、文本。
"""

import os
import re
import argparse
import sys
from typing import List, Tuple


def find_markdown_files(directory: str) -> List[str]:
    """递归查找目录下所有 .md 文件"""
    md_files = []
    for root, _, files in os.walk(directory):
        for file in files:
            if file.lower().endswith('.md'):
                md_files.append(os.path.join(root, file))
    return md_files


def extract_content_from_file(filepath: str) -> List[Tuple[str, int, str, str]]:
    """
    从单个 Markdown 文件中提取标题和加粗文本。
    返回列表，每个元素为 (文件名, 行号, 类型, 文本)
    """
    results = []
    try:
        # 尝试用 utf-8 编码打开，失败则用 latin-1
        with open(filepath, 'r', encoding='utf-8', errors='replace') as f:
            lines = f.readlines()
    except Exception as e:
        print(f"警告：无法读取文件 {filepath}: {e}", file=sys.stderr)
        return results

    # 正则表达式：匹配行首 1-5 个 #，后跟至少一个空格，然后是标题文本
    heading_pattern = re.compile(r'^(#{1,5})\s+(.*)')
    # 匹配加粗文本：**文本**，支持跨单词，但不跨行
    bold_pattern = re.compile(r'\*\*(.+?)\*\*')

    for line_num, line in enumerate(lines, start=1):
        line = line.rstrip('\n')
        
        # 检查标题
        match = heading_pattern.match(line)
        if match:
            level = len(match.group(1))  # # 的数量
            text = match.group(2).strip()
            if text:  # 忽略空标题
                results.append((filepath, line_num, f"H{level}", text))
        
        # 检查加粗文本（同一行可能有多个）
        for bold_match in bold_pattern.finditer(line):
            text = bold_match.group(1).strip()
            if text:  # 忽略空加粗
                results.append((filepath, line_num, "BOLD", text))
    
    return results


def main():
    parser = argparse.ArgumentParser(
        description='扫描 Markdown 文件，提取标题和加粗文本'
    )
    parser.add_argument(
        'directory',
        nargs='?',
        default='.',
        help='要扫描的目录路径（默认为当前目录）'
    )
    parser.add_argument(
        '-o', '--output',
        default='/tmp/content.index',
        help='输出文件路径（默认为 /tmp/content.index）'
    )
    parser.add_argument(
        '-v', '--verbose',
        action='store_true',
        help='显示详细处理信息'
    )
    
    args = parser.parse_args()
    
    # 确保目录存在
    if not os.path.isdir(args.directory):
        print(f"错误：目录 '{args.directory}' 不存在", file=sys.stderr)
        sys.exit(1)
    
    # 查找所有 Markdown 文件
    md_files = find_markdown_files(args.directory)
    if args.verbose:
        print(f"找到 {len(md_files)} 个 Markdown 文件")
    
    # 提取内容
    all_results = []
    for filepath in md_files:
        if args.verbose:
            print(f"处理文件：{filepath}")
        results = extract_content_from_file(filepath)
        all_results.extend(results)
    
    # 写入输出文件
    try:
        with open(args.output, 'w', encoding='utf-8') as f:
            # 写入表头
            f.write("文件名\t行号\t类型\t文本\n")
            for filepath, line_num, content_type, text in all_results:
                # 将绝对路径转换为相对于扫描目录的路径，便于阅读
                try:
                    rel_path = os.path.relpath(filepath, args.directory)
                except ValueError:
                    rel_path = filepath
                f.write(f"{rel_path}\t{line_num}\t{content_type}\t{text}\n")
        
        if args.verbose:
            print(f"结果已保存到 {args.output}")
            print(f"共找到 {len(all_results)} 条记录")
        else:
            print(f"扫描完成，共找到 {len(all_results)} 条记录，结果已保存到 {args.output}")
    
    except Exception as e:
        print(f"错误：无法写入输出文件 {args.output}: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == '__main__':
    main()