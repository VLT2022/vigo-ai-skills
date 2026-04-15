# 手动安装指南

如果你不想跑 `./install.sh`，或者 `install.sh` 没检测到你的 AI 工具，请按本文档的对应章节手动安装。

每个章节包含 3 件事：
1. **Skill 安装路径**（把 `skills/vigo-find-house/` 复制到哪里）
2. **MCP 配置文件位置**（把 `mcp-config.json` 里的 `vigo-mcp` 节点粘贴到哪里）
3. **如何验证 Skill 已生效**

---

## Claude Code

### Skill 安装路径

```
~/.claude/skills/vigo-find-house/         # 全局可用
<project>/.claude/skills/vigo-find-house/ # 仅当前项目可用
```

**推荐全局安装**（所有项目都能用）：

```bash
mkdir -p ~/.claude/skills
cp -R skills/vigo-find-house ~/.claude/skills/
```

### MCP 配置

编辑 `~/.claude/.mcp.json`（若不存在，新建）或者在项目根目录创建 `.mcp.json`：

```json
{
  "mcpServers": {
    "vigo-mcp": {
      "transport": "http",
      "url": "https://mcp.vigolive.cn/mcp",
      "headers": {
        "X-API-Key": "vgk_live_你的真实key"
      }
    }
  }
}
```

重启 Claude Code。

### 验证

在 Claude Code 里输入 `/mcp` 应当看到 `vigo-mcp` 服务和 5 个工具（`search_houses` 等）。

直接试 slash command：

```
/mcp__vigo-mcp__search_houses city="北京" price_max=6000
```

自然语言触发：

```
帮我在上海陆家嘴找 8000 以下整租
```

AI 应当看到 `vigo-find-house` Skill 加载提示，并在识别意图后主动调 vigo-mcp 工具。

> 截图占位：`docs/images/claude-code-mcp-list.png`
> 截图占位：`docs/images/claude-code-skill-loaded.png`

---

## Claude Desktop

### Skill 安装路径

| 平台 | 路径 |
|------|------|
| macOS | `~/Library/Application Support/Claude/skills/vigo-find-house/` |
| Linux | `~/.config/Claude/skills/vigo-find-house/` |
| Windows | `%APPDATA%\Claude\skills\vigo-find-house\` |

macOS 示例：

```bash
mkdir -p "$HOME/Library/Application Support/Claude/skills"
cp -R skills/vigo-find-house "$HOME/Library/Application Support/Claude/skills/"
```

### MCP 配置

编辑对应平台的配置文件：

| 平台 | 配置文件 |
|------|---------|
| macOS | `~/Library/Application Support/Claude/claude_desktop_config.json` |
| Linux | `~/.config/Claude/claude_desktop_config.json` |
| Windows | `%APPDATA%\Claude\claude_desktop_config.json` |

添加或合并 `mcpServers.vigo-mcp` 节点：

```json
{
  "mcpServers": {
    "vigo-mcp": {
      "transport": "http",
      "url": "https://mcp.vigolive.cn/mcp",
      "headers": {
        "X-API-Key": "vgk_live_你的真实key"
      }
    }
  }
}
```

**完全退出** Claude Desktop（不是关窗口，要从菜单或 ⌘Q 退出）并重开。

### 验证

打开一个新对话，点击底部的工具图标，应当能看到 `vigo-mcp` 列出的 5 个工具。

试着说：

> 帮我找北京望京 SOHO 附近通勤 30 分钟内的整租，5000 左右

> 截图占位：`docs/images/claude-desktop-tools-panel.png`
> 截图占位：`docs/images/claude-desktop-config-file.png`

---

## Cursor

### Skill 安装路径

Cursor 原生不用 Anthropic SKILL.md 格式，但支持 `.cursor/rules/` 目录加载 markdown 规则文件。本 Skill 可作为 `.cursor/rules/vigo-find-house/SKILL.md` 加载（Cursor 会把目录下所有 md 文件作为 context）：

```bash
mkdir -p ~/.cursor/rules
cp -R skills/vigo-find-house ~/.cursor/rules/
```

或者仅在某个项目生效：

```bash
mkdir -p <project>/.cursor/rules
cp -R skills/vigo-find-house <project>/.cursor/rules/
```

### MCP 配置

Cursor 的 MCP 配置在 `~/.cursor/mcp.json`（或项目 `.cursor/mcp.json`）：

```json
{
  "mcpServers": {
    "vigo-mcp": {
      "url": "https://mcp.vigolive.cn/mcp",
      "headers": {
        "X-API-Key": "vgk_live_你的真实key"
      }
    }
  }
}
```

重启 Cursor。

### 验证

打开 Cursor → Settings → MCP，应当看到 `vigo-mcp` 标记为已连接。

在对话里 `@vigo-mcp` 或直接说自然语言都能触发。

> 截图占位：`docs/images/cursor-mcp-settings.png`

> **注意**：Cursor 对 SKILL.md 的 YAML frontmatter 支持不完整（它主要读 `.mdc` 格式）。Skill 里的 description 触发词机制在 Cursor 里效果打折，但工具本身可用。如果发现 AI 不主动调 vigo-mcp，可显式 @mention 或贴一下 SKILL.md 内容作为 context。

---

## Windsurf

### Skill 安装路径

```bash
mkdir -p ~/.codeium/windsurf/skills
cp -R skills/vigo-find-house ~/.codeium/windsurf/skills/
```

项目级：

```bash
mkdir -p <project>/.windsurf/skills
cp -R skills/vigo-find-house <project>/.windsurf/skills/
```

### MCP 配置

`~/.codeium/windsurf/mcp_config.json`：

```json
{
  "mcpServers": {
    "vigo-mcp": {
      "url": "https://mcp.vigolive.cn/mcp",
      "headers": {
        "X-API-Key": "vgk_live_你的真实key"
      }
    }
  }
}
```

重启 Windsurf（完全退出）。

### 验证

在 Cascade 面板里能看到 `vigo-mcp` 的工具列表。

> 截图占位：`docs/images/windsurf-cascade-tools.png`

---

## Codex CLI (OpenAI)

### Skill 安装路径

```bash
mkdir -p ~/.codex/skills
cp -R skills/vigo-find-house ~/.codex/skills/
```

### MCP 配置

Codex CLI 用 TOML 配置。编辑 `~/.codex/config.toml`，添加或合并：

```toml
[mcp_servers.vigo-mcp]
transport = "http"
url = "https://mcp.vigolive.cn/mcp"

[mcp_servers.vigo-mcp.headers]
"X-API-Key" = "vgk_live_你的真实key"
```

### 验证

```bash
codex /mcp list
```

应当看到 `vigo-mcp` 和 5 个工具。

```bash
codex /mcp call vigo-mcp.search_houses '{"city": "北京", "price_max": 6000}'
```

> 截图占位：`docs/images/codex-mcp-list.png`

---

## OpenCode / OpenClaw

### Skill 安装路径

```bash
# OpenCode
mkdir -p ~/.opencode/skills
cp -R skills/vigo-find-house ~/.opencode/skills/

# OpenClaw (如果是 OpenClaw 而非 OpenCode)
mkdir -p ~/.openclaw/skills
cp -R skills/vigo-find-house ~/.openclaw/skills/
```

### MCP 配置

编辑 `~/.opencode/config.json`（OpenClaw 为 `~/.openclaw/config.json`），合并：

```json
{
  "mcpServers": {
    "vigo-mcp": {
      "transport": "http",
      "url": "https://mcp.vigolive.cn/mcp",
      "headers": {
        "X-API-Key": "vgk_live_你的真实key"
      }
    }
  }
}
```

### 验证

启动 OpenCode / OpenClaw 后在对话里输入 `/mcp` 或直接提到找房需求。

> 截图占位：`docs/images/opencode-mcp.png`

---

## Cline / Continue / Zed（简要）

这些工具用相同的 MCP 配置方式（HTTP + X-API-Key header），但对 Skill 的支持各家不同，建议只配 MCP，不装 Skill：

- **Cline**：VSCode 扩展，配置在 VSCode Settings → Cline → MCP
- **Continue**：`.continue/config.yaml`，添加 mcpServers
- **Zed**：Settings → AI → MCP

Skill 未必生效，但 5 个工具都能用 `@vigo-mcp` 或手动提及调用。

---

## 验证 Skill 已生效的通用方法

不论什么工具，以下对话应该能稳定触发 vigo-mcp 调用：

```
用户：帮我在北京望京 SOHO 附近找 5000 以下整租，通勤 30 分钟内
```

预期 AI 行为：

1. 识别到 `city=北京` + `workplace=望京SOHO` + `max_commute_minutes=30` + `price_max=5000`
2. 调用 `vigo-mcp.search_by_commute(...)` 工具
3. 返回 markdown 表格展示前 5 套房源，每套带通勤时间

如果 AI 只回复文字没调工具，说明 Skill 没生效或 MCP 未连通。按 [`troubleshooting.md`](troubleshooting.md) 排查。
