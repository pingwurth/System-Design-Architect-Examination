#!/usr/bin/env python3
"""Scan markdown chapter files for headings and bold text, then search by keywords.

Usage:
    python scan_markdown.py <chapters_dir> <keyword> [<keyword> ...]

Output: JSON array of matches, each with file, line, type, text, and context.
"""

import json
import os
import re
import sys
from pathlib import Path


def extract_structured_elements(filepath: str):
    """Extract headings and bold text from a markdown file with line numbers."""
    elements = []
    with open(filepath, "r", encoding="utf-8") as f:
        lines = f.readlines()

    for i, line in enumerate(lines, start=1):
        stripped = line.strip()
        if not stripped:
            continue

        # Headings: ##, ###, ####, etc.
        heading_match = re.match(r"^(#{1,6})\s+(.+)$", stripped)
        if heading_match:
            level = len(heading_match.group(1))
            text = heading_match.group(2).strip()
            elements.append({
                "file": filepath,
                "line": i,
                "type": f"h{level}",
                "text": text,
                "raw": stripped,
            })
            continue

        # Bold text: **text** (may appear multiple times per line)
        bold_matches = re.findall(r"\*\*(.+?)\*\*", stripped)
        for bold_text in bold_matches:
            elements.append({
                "file": filepath,
                "line": i,
                "type": "bold",
                "text": bold_text.strip(),
                "raw": stripped,
            })

    return elements


def get_context(filepath: str, target_line: int, window: int = 5):
    """Read surrounding lines for context around a match."""
    with open(filepath, "r", encoding="utf-8") as f:
        lines = f.readlines()

    start = max(0, target_line - window - 1)
    end = min(len(lines), target_line + window)
    context_lines = []
    for i in range(start, end):
        prefix = ">>>" if i == target_line - 1 else "   "
        context_lines.append(f"{prefix} {i + 1:>5}: {lines[i].rstrip()}")
    return "\n".join(context_lines)


def search_elements(elements, keywords):
    """Search elements for keyword matches. Returns scored matches."""
    matches = []
    for elem in elements:
        text_lower = elem["text"].lower()
        raw_lower = elem["raw"].lower()
        score = 0
        matched_keywords = []

        for kw in keywords:
            kw_lower = kw.lower()
            if kw_lower in text_lower:
                # Exact match in heading/bold text scores high
                score += 10
                matched_keywords.append(kw)
            elif kw_lower in raw_lower:
                # Match in the raw line (partial) scores lower
                score += 3
                matched_keywords.append(kw)
            else:
                # Partial match: require at least 3 consecutive characters
                # to avoid false positives from common 2-char bigrams
                # (e.g., "计算" in "量子计算" matching "计算机系统")
                min_ngram = min(3, len(kw_lower))
                matched_partial = False
                for j in range(len(kw_lower) - min_ngram + 1):
                    ngram = kw_lower[j:j + min_ngram]
                    if ngram in text_lower:
                        # Score proportional to match coverage
                        coverage = min_ngram / len(kw_lower)
                        score += max(2, int(coverage * 8))
                        if kw not in matched_keywords:
                            matched_keywords.append(kw)
                        matched_partial = True
                        break

        if score > 0:
            # Headings score higher than bold text
            if elem["type"].startswith("h"):
                level = int(elem["type"][1])
                score += max(0, 7 - level)  # h1 gets +6, h2 +5, etc.

            elem["score"] = score
            elem["matched_keywords"] = matched_keywords
            matches.append(elem)

    # Sort by score descending
    matches.sort(key=lambda m: m["score"], reverse=True)
    return matches


def main():
    if len(sys.argv) < 3:
        print("Usage: python scan_markdown.py <chapters_dir> <keyword> [<keyword> ...]",
              file=sys.stderr)
        sys.exit(1)

    chapters_dir = sys.argv[1]
    keywords = sys.argv[2:]

    if not os.path.isdir(chapters_dir):
        print(json.dumps({"error": f"Directory not found: {chapters_dir}"}))
        sys.exit(1)

    # Collect all markdown files sorted by name
    md_files = sorted(Path(chapters_dir).glob("*.md"))
    if not md_files:
        print(json.dumps({"error": f"No .md files found in {chapters_dir}"}))
        sys.exit(1)

    # Extract all structured elements
    all_elements = []
    for md_file in md_files:
        all_elements.extend(extract_structured_elements(str(md_file)))

    # Search for keyword matches
    matches = search_elements(all_elements, keywords)

    # Add context to top matches (limit to top 20 to keep output manageable)
    top_matches = matches[:20]
    for m in top_matches:
        m["context"] = get_context(m["file"], m["line"])

    # Build summary
    result = {
        "chapters_dir": chapters_dir,
        "total_files": len(md_files),
        "total_elements_scanned": len(all_elements),
        "keywords": keywords,
        "total_matches": len(matches),
        "top_matches": top_matches,
    }

    print(json.dumps(result, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
