# cutflow_flutter AI 约定

## 枢纽汇报约定（ai_project）

本项目由 `D:\Code\ai_project` 枢纽纳管。任何 AI 智能体（Claude Code / Codex / OpenCode 等）在本项目内完成一段执行后（任务完成、部分完成或中断退出），必须：

1. 在 `D:\Code\ai_project\reports\cutflow_flutter\` 下新建执行报告 `YYYY-MM-DD-<NN>-<slug>.md`（NN=当日两位序号；slug=英文小写-连字符任务标识），格式照 `D:\Code\ai_project\templates\report-template.md`；
2. 报告写完才算任务结束；无法完成时也要写中断报告（status=blocked，写明卡点）；
3. 除上述报告外，不得改动 `D:\Code\ai_project` 枢纽层的任何其他文件。

本项目原有约定仍然优先于本节。
