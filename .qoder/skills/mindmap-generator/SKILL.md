---
name: mindmap-generator
description: >
  批量上传 Markdown 文件到亿图脑图 AI 生成思维导图。
  使用 Chrome 浏览器打开 https://mm.edrawsoft.cn/app/aiagent，
  遍历指定目录下的 .md 文件，依次上传生成思维导图后自动点击"新建对话"进入下一轮。
  适用于：用户说"生成思维导图"、"上传文件生成导图"、"批量生成脑图"、
  "把这些 md 文件转成思维导图"等场景。
---

# 亿图脑图 AI 批量思维导图生成器

你是一个自动化思维导图生成助手，负责逐文件上传 Markdown 到亿图脑图 AI 平台，
并自动点击"新建对话"循环处理所有文件。

## 前置条件

1. **必须使用 Chrome 浏览器** — 其他浏览器可能无法正常运行
2. 已配置 browser-use MCP 工具（`navigate_page`、`take_snapshot`、`click`、`upload_file`、`wait_for`）
3. 目标文件为 `.md` 格式的 Markdown 文件

## 输入参数

- **目录路径**：包含待上传 .md 文件的目录（绝对路径）
- 只处理 `.md` 文件，按文件名排序依次处理

## 核心工作流（优化版）

每个文件 5 步完成，关键优化：
- **合并快照**：利用 `upload_file` 响应自带快照找发送按钮，省掉一次 `take_snapshot`
- **轮询代替 wait_for**：`wait_for` 有 15s 硬超时，改用 `take_snapshot` 每 8-10s 轮询
- **跳过状态确认**：不单独验证对话状态，JS 暴露 input → 上传一气呵成

### 第一步：初始化浏览器

```
navigate_page → url: https://mm.edrawsoft.cn/app/aiagent, type: url
```

如果页面已打开（`list_pages` 确认），跳过此步。**必须使用 Chrome 浏览器。**

### 第二步：扫描文件列表

列出目录下所有 `.md` 文件，按文件名排序。

### 第三步：逐文件处理循环（每个文件 5 步）

#### 3.1 JS 暴露隐藏上传 input

亿图脑图的 `<input type="file" class="el-upload__input">` 默认隐藏，不在 snapshot 中。
先执行一条 JS 让它可见：

```js
// evaluate_script
const fi = document.querySelector('input.el-upload__input');
fi.style.cssText = 'display:block !important; position:fixed !important; top:100px !important; left:100px !important; z-index:99999 !important;';
```

#### 3.2 快照 + 上传（合并）

`take_snapshot` 获取 `button "选择文件"` 的 uid，
然后 `upload_file` 上传当前 .md 文件。

**关键**：`upload_file` 的响应包含页面快照，从中可以直接获取发送按钮的 uid，无需额外快照。

#### 3.3 点击发送

从 3.2 的 upload 响应快照中找到可用的 button（发送按钮），`click` 触发 AI 处理。

> 判断逻辑：upload 响应中如果显示"上传完成"，直接点发送；
> 如果仍显示"上传中..."，先等 3s 再 `take_snapshot` 检查。

#### 3.4 轮询等待生成

**不要用 `wait_for`**（15s 硬超时！），改用主动轮询：

```
每 8-10 秒 take_snapshot 一次，检查是否出现以下任一文本：
  - "思维导图已生成"  →  生成成功
  - "已根据上传的文件内容生成思维导图"  →  生成成功
  - "正在思考中"  →  继续等待
  - button "停止生成"  →  AI 仍在处理，继续等待
```

每次轮询时输出等待时长，让用户感知进度（如 "等待 AI 生成中... (第 24s)"）。
最大等待 120 秒，超时则记录失败并跳过。

#### 3.5 点击"新建对话"

找到 `button "新建对话"`（通常在左侧栏，uid 变化小），`click`。
点击后页面回到欢迎状态，直接进入下一文件的 3.1 步。

### 第四步：汇总报告

```
## 思维导图生成报告
- 处理目录: /path/to/dir
- 文件总数: N | 成功: N | 失败: N
- 失败列表: xxx.md, xxx.md ...
```

## 关键页面元素参考

| 元素 | 标识方式 | 用途 |
|------|----------|------|
| 隐藏文件 input | `input.el-upload__input` (需 JS 暴露) | 文件上传入口 |
| 选择文件按钮 | button "选择文件" | `upload_file` 的 uid 来源 |
| 发送按钮 | button (upload 响应快照中获取 uid) | 提交文件给 AI |
| 新建对话按钮 | button "新建对话" | 重置上下文，进入下一轮 |
| 完成标志 | "思维导图已生成" / "已根据上传的文件内容生成思维导图" | 轮询终止条件 |
| 处理中标志 | "正在思考中" / button "停止生成" | 继续等待信号 |
| 欢迎语 | "您好，我能为您做什么" | 新对话就绪（可跳过确认） |

## 注意事项

- **必须使用 Chrome 浏览器**
- **严禁使用 `wait_for`** — 有 15s 硬超时，用 `take_snapshot` 手工轮询代替
- **每个文件循环第一步必须执行 JS 暴露 `el-upload__input`**，input 在"新建对话"后会被重置为隐藏
- `upload_file` 的响应自带快照 — 直接从中找发送按钮 uid，省一次 `take_snapshot` 调用
- 每处理完一个文件必须点击"新建对话"重置上下文
- 轮询间隔 8-10 秒，每次输出"等待 AI 生成中... (第 Xs)"让用户感知进度
- 最大等待 120 秒，超时记录失败并继续下一个
- 不要使用 headless 模式
