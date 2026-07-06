---
name: edrawmind-mindmap-generator
description: Automate uploading markdown files to EdrawMind AI (万兴脑图) web application to generate mind maps. Use when the user wants to generate mind maps from markdown files, batch process multiple markdown files into mind maps, or when mentioning EdrawMind, 万兴脑图, or mind map generation from files.
---

# EdrawMind Mind Map Generator

Automate the workflow of uploading markdown files to EdrawMind AI web application and generating mind maps.

## Prerequisites

1. Chrome browser must be available via Chrome DevTools MCP
2. User must be logged in to EdrawMind (login dialog will appear if not authenticated)
3. Target URL: `https://mm.edrawsoft.cn/app/aiagent`

## Core Workflow

### Single File Processing

For each markdown file:

1. **Navigate to EdrawMind AI**
   ```
   chrome-devtools: navigate_page → url: "https://mm.edrawsoft.cn/app/aiagent"
   ```

2. **Handle login if needed**
   - Check snapshot for login dialog
   - If login form appears with pre-filled credentials, click login button
   - Wait for page to reload with user account visible

3. **Make file input visible**
   ```javascript
   evaluate_script: () => {
     const fileInput = document.querySelector('input[name="file"]');
     if (fileInput) {
       fileInput.style.display = 'block';
       fileInput.style.position = 'relative';
       fileInput.style.zIndex = '9999';
       fileInput.style.opacity = '1';
       return 'made visible';
     }
     return 'not found';
   }
   ```

4. **Take snapshot to find "Choose Files" button uid**

5. **Upload the file**
   ```
   chrome-devtools: upload_file → 
     uid: <Choose Files button uid>
     filePath: <absolute path to .md file>
   ```

6. **Wait for upload completion**
   ```
   chrome-devtools: wait_for → text: ["上传完成"]
   ```

7. **Click send button**
   - Find the send button uid from snapshot (previously disabled button that becomes enabled after upload)
   - ```
     chrome-devtools: click → uid: <send button uid>
     ```

8. **Wait for generation to complete**
   ```javascript
   evaluate_script: async () => {
     const waitForStopDisappear = () => new Promise((resolve) => {
       const check = () => {
         const buttons = Array.from(document.querySelectorAll('button'));
         const stopBtnExists = buttons.some(b => b.textContent.includes('停止生成'));
         if (!stopBtnExists) { resolve('generation_complete'); }
         else { setTimeout(check, 2000); }
       };
       check();
     });
     return await Promise.race([
       waitForStopDisappear(), 
       new Promise((resolve) => setTimeout(() => resolve('timeout'), 120000))
     ]);
   }
   ```

9. **Create new conversation for next file**
   ```
   chrome-devtools: click → uid: <新建对话 button uid>
   ```

### Batch Processing

For multiple files, repeat steps 2-9 for each file:

```bash
# Example: Process all chapter 4 files
files=(
  "第4章_442_对称密钥加密算法.md"
  "第4章_443_非对称密钥加密算法.md"
  "第4章_451_对称密钥的分配与管理.md"
)
```

## Important Notes

- **File input is hidden by default** - must use JavaScript to make it visible
- **Send button is disabled until file is uploaded** - wait for upload completion
- **Generation takes time** - use the "停止生成" button disappearance as completion indicator
- **Each file needs a new conversation** - click "新建对话" between files
- **Supported file types**: .pdf, .docx, .txt, .md, .xlsx, .csv, .pptx, .png, .jpg, .jpeg, .html, .htm, .mp3, .mp4, .m4a, .wav, .aac, .json, .yml, .yaml, .xml, .opml

## Error Handling

- If login fails, check if credentials are correct
- If file upload fails, verify file path and file type
- If generation times out (120s), check network connection
- If element uids change, take new snapshot to get current uids
