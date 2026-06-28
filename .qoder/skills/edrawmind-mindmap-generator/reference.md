# EdrawMind Mind Map Generator - Reference

## Technical Details

### Page Structure

The EdrawMind AI page has the following key elements:

1. **Navigation sidebar** - Contains links to workspace, files, knowledge base, etc.
2. **Chat history** - Shows previous conversations
3. **Input area** - Contains the text input and file upload functionality
4. **Model selector** - Currently uses DeepSeek-V4-Flash
5. **Output area** - Displays generated mind maps

### Element Identification

Elements are identified by unique identifiers (uid) in the accessibility tree. These uids change between page loads, so always take a fresh snapshot before interacting with elements.

Key elements to identify:
- `input[name="file"]` - Hidden file input element
- `.attachment` - The attachment button that triggers file input
- Send button - Disabled until file is uploaded, becomes enabled after upload
- "新建对话" button - Creates a new conversation
- "停止生成" button - Appears during generation, disappears when complete

### JavaScript Commands

#### Make File Input Visible
```javascript
() => {
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

#### Check Generation Status
```javascript
async () => {
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

## MCP Tool Usage

### Chrome DevTools MCP Tools

1. **navigate_page** - Navigate to URLs
2. **take_snapshot** - Get page structure and element uids
3. **upload_file** - Upload files to file input elements
4. **click** - Click on elements by uid
5. **wait_for** - Wait for text to appear on page
6. **evaluate_script** - Execute JavaScript in page context

### Tool Call Sequence

For each file processing:
1. `navigate_page` (only once at start)
2. `take_snapshot` (to find elements)
3. `evaluate_script` (make file input visible)
4. `take_snapshot` (to find Choose Files button uid)
5. `upload_file` (upload the markdown file)
6. `wait_for` (wait for "上传完成")
7. `click` (click send button)
8. `evaluate_script` (wait for generation to complete)
9. `click` (click "新建对话" for next file)

## Supported File Types

The EdrawMind AI supports the following file types for upload:
- Documents: .pdf, .docx, .txt, .md, .xlsx, .csv, .pptx
- Images: .png, .jpg, .jpeg
- Web: .html, .htm
- Audio: .mp3, .m4a, .wav, .aac
- Video: .mp4
- Data: .json, .yml, .yaml, .xml, .opml

## Troubleshooting

### Common Issues

1. **Login dialog appears**
   - Check if user credentials are saved in browser
   - Click login button if credentials are pre-filled
   - If not pre-filled, user must log in manually

2. **File input not found**
   - The file input element may have changed
   - Take a new snapshot and search for `input[name="file"]`

3. **Upload fails**
   - Verify file path is absolute and correct
   - Check file type is supported
   - Ensure file size is under 100MB

4. **Generation timeout**
   - Default timeout is 120 seconds
   - Increase timeout for larger files
   - Check network connection

5. **Element uid changed**
   - Always take a fresh snapshot before interacting
   - Never cache uids between page loads
