# 周报自动发布说明

## 首次使用前

请先通过 GitHub Desktop 登录 GitHub，或在 PowerShell 中手动执行一次 `git push` 并完成登录。登录凭据保存后，发布脚本才能自动推送。

## 每周使用方法

打开 PowerShell，进入仓库：

```powershell
cd "C:\Users\豆豆\Desktop\营养教练数据分析项目\community-dashboard"
```

执行发布脚本：

```powershell
powershell -ExecutionPolicy Bypass -File ".\scripts\publish-weekly-report.ps1" `
  -HtmlFile "C:\周报文件\weekly-report.html" `
  -PublishFolder "weekly-dashboard-20260601-0607"
```

脚本会自动：

1. 在仓库根目录创建发布文件夹。
2. 将输入的 HTML 复制为该文件夹下的 `index.html`。
3. 执行 `git add`、`git commit` 和 `git push`。
4. 使用执行当天日期生成提交信息，例如 `更新周报-20260609`。
5. 输出 GitHub Pages 访问链接。

链接格式：

```text
https://jackluliqiang-del.github.io/community-dashboard/发布文件夹名称/
```

## 文件夹命名规则

只允许使用小写英文字母、数字和连字符，不允许中文、空格或路径符号。

推荐格式：

```text
weekly-dashboard-YYYYMMDD-MMDD
```

例如：

```text
weekly-dashboard-20260601-0607
```

如果发布文件夹已经存在，脚本会停止并要求输入大写 `YES` 确认。未确认时不会覆盖历史页面。
