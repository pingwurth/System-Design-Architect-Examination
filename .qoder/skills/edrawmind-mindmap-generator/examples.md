# EdrawMind Mind Map Generator - Examples

## Example 1: Single File Processing

**User request**: "Generate a mind map from 第4章_442_对称密钥加密算法.md"

**Agent workflow**:

1. Navigate to EdrawMind AI
```
chrome-devtools: navigate_page → url: "https://mm.edrawsoft.cn/app/aiagent"
```

2. Make file input visible
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

3. Take snapshot to find "Choose Files" button
```
chrome-devtools: take_snapshot → (returns uid for Choose Files button)
```

4. Upload file
```
chrome-devtools: upload_file → 
  uid: "5_1"
  filePath: "/path/to/第4章_442_对称密钥加密算法.md"
```

5. Wait for upload
```
chrome-devtools: wait_for → text: ["上传完成"]
```

6. Click send
```
chrome-devtools: click → uid: "1_44"
```

7. Wait for generation
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

**Result**: Mind map generated successfully with content about symmetric key encryption algorithms.

---

## Example 2: Batch File Processing

**User request**: "Generate mind maps for all chapter 4 files"

**Agent workflow**:

```bash
# List of files to process
files=(
  "第4章_442_对称密钥加密算法.md"
  "第4章_443_非对称密钥加密算法.md"
  "第4章_451_对称密钥的分配与管理.md"
  "第4章_452_公钥加密体制的密钥管理.md"
  "第4章_453_公钥加密分配单钥密码体制的密钥.md"
)
```

For each file:
1. Make file input visible (JavaScript)
2. Take snapshot to find uid
3. Upload file
4. Wait for upload completion
5. Click send button
6. Wait for generation to complete
7. Click "新建对话" for next file

**Result**: 5 mind maps generated, one for each chapter 4 file.

---

## Example 3: Handling Login Dialog

**Scenario**: User is not logged in

**Agent workflow**:

1. Navigate to EdrawMind AI
```
chrome-devtools: navigate_page → url: "https://mm.edrawsoft.cn/app/aiagent"
```

2. Take snapshot and detect login dialog
```
chrome-devtools: take_snapshot → (shows login form with uid)
```

3. Click login button (if credentials are pre-filled)
```
chrome-devtools: click → uid: "2_15"
```

4. Wait for page to reload
```
chrome-devtools: wait_for → text: ["万兴脑图AI", "新建对话"]
```

5. Continue with file upload workflow

---

## Example 4: Error Recovery

**Scenario**: Element uid changed after page reload

**Problem**: After clicking "新建对话", the file input uid changed

**Solution**:
1. Always take a fresh snapshot before interacting with elements
2. Never assume uids are the same between page states
3. Use JavaScript to find elements by selector, not by uid

```javascript
// Find file input by selector, not uid
() => {
  const fileInput = document.querySelector('input[name="file"]');
  return fileInput ? 'found' : 'not found';
}
```

---

## Example 5: Custom Timeout for Large Files

**Scenario**: Processing a large markdown file (100KB+)

**Agent workflow**:

1. Increase timeout for generation wait
```javascript
async () => {
  const waitForStopDisappear = () => new Promise((resolve) => {
    const check = () => {
      const buttons = Array.from(document.querySelectorAll('button'));
      const stopBtnExists = buttons.some(b => b.textContent.includes('停止生成'));
      if (!stopBtnExists) { resolve('generation_complete'); }
      else { setTimeout(check, 3000); } // Increased from 2000ms to 3000ms
    };
    check();
  });
  return await Promise.race([
    waitForStopDisappear(), 
    new Promise((resolve) => setTimeout(() => resolve('timeout'), 300000)) // 5 minutes instead of 2
  ]);
}
```

2. Monitor progress via snapshots
```
chrome-devtools: take_snapshot → (check for generation progress)
```

---

## Common Patterns

### Pattern 1: File Input Visibility Toggle

Always make the hidden file input visible before uploading:

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

### Pattern 2: Generation Completion Check

Wait for the "停止生成" button to disappear:

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

### Pattern 3: Snapshot Before Interaction

Always take a snapshot before clicking elements:

```
chrome-devtools: take_snapshot → (get current uids)
chrome-devtools: click → uid: <current uid from snapshot>
```
