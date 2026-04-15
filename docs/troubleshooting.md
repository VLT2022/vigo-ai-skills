# 常见问题排查

这里列出 vigo-ai-skills + vigo-mcp 接入过程中最常遇到的 4 类问题，每个问题都给出原因 + 具体排查步骤。

---

## 1. AI 工具没有触发 Skill / 不主动调 vigo-mcp

**症状**：你跟 AI 说"帮我在北京找 6000 以下整租"，AI 用自己的知识给建议，但没调用 vigo-mcp 工具。

### 排查 1.1：Skill 是否在正确路径

确认 `vigo-find-house` 目录复制到了对应工具的 skills 目录：

```bash
# Claude Code
ls ~/.claude/skills/vigo-find-house/SKILL.md

# Claude Desktop (macOS)
ls "$HOME/Library/Application Support/Claude/skills/vigo-find-house/SKILL.md"

# Codex CLI
ls ~/.codex/skills/vigo-find-house/SKILL.md
```

如果路径不存在，重新跑 `./install.sh` 或按 [`how-to-install.md`](how-to-install.md) 手动复制。

### 排查 1.2：Skill 的 frontmatter 是否完整

打开 `SKILL.md`，确认第一行是 `---`，接下来是 YAML frontmatter，包含 `name` 和 `description` 字段。Description 必须有丰富的触发词（找房、租房、北京、上海等），AI 客户端才会在用户说"找房"时把 Skill 加载进 context。

### 排查 1.3：客户端是否重启

许多 MCP 客户端只在启动时扫描 skills 目录。复制 Skill 文件后**完全退出**并重启：

- Claude Desktop：macOS 用 ⌘Q 或菜单 `Claude → Quit`，不是关闭窗口
- Cursor / Windsurf：同上
- Claude Code：关掉所有 claude CLI 进程

### 排查 1.4：显式触发测试

即使 Skill 没生效，你也可以显式调用 MCP 工具验证 MCP 层是否通：

```
/mcp__vigo-mcp__search_houses city="北京" price_max=6000
```

或自然语言里直接说：

```
请使用 vigo-mcp 工具搜北京 6000 以下的整租
```

如果这样能调通，说明问题只在 Skill 触发层；如果还是不通，说明 MCP 层本身有问题，跳到第 2 节。

### 排查 1.5：Cursor / Windsurf 特殊情况

这两家客户端对 Anthropic SKILL.md 格式支持不完整（Cursor 主要读 `.mdc`）。如果 AI 在 Cursor 里不主动调用，请改为**每次对话显式 @mention**：

```
@vigo-mcp 帮我找北京 6000 以下整租
```

---

## 2. MCP 调用返回 `Invalid API Key` / `401 Unauthorized`

**症状**：AI 调工具后报认证错误，或者客户端 MCP 状态显示"连接失败"。

### 排查 2.1：Key 是否正确粘贴

打开对应工具的 MCP 配置文件，检查：

- `X-API-Key` 的值是否以 `vgk_live_` 开头
- 是否还是占位符 `<PASTE_YOUR_VGK_LIVE_KEY_HERE>`
- 是否被引号包裹（必须有引号）
- 前后是否有**空格或换行**（粘贴时常见问题）

### 排查 2.2：Key 是否已被吊销

打开 vigolive 小程序 → 我的 → AI 接入，检查这把 key 是否还在 active 列表里。如果已经吊销或不在列表，重新生成一把。

### 排查 2.3：Key 是否过期

自助生成的 key 默认不过期，但企业版或被 admin 手动设置过 `expires_at` 的 key 可能已过期。通过小程序看该 key 的状态；如已失效，吊销 + 新建。

### 排查 2.4：Redis 缓存延迟

刚刚在小程序新生成或刚吊销的 key，vigo-mcp 侧有最多 **5 分钟**的缓存延迟。如果刚操作完就立刻调，等 5 分钟再试。

### 排查 2.5：Header 名称错误

header 必须是 `X-API-Key`（注意大小写、注意连字符）。写成以下都是错的：

- ❌ `X-Api-Key`（最后一个 Key 里的 K 小写）—— HTTP header 不区分大小写应该能容忍，但某些客户端严格
- ❌ `Authorization: Bearer vgk_live_xxx` —— vigo-mcp **也**接受，但建议用 `X-API-Key`
- ❌ `api-key` / `apikey` —— 错误

---

## 3. MCP 调用返回 `Quota exceeded` / JSON-RPC error `-32001`

**症状**：前几次调用正常，后面突然开始全部报配额超限。

### 排查 3.1：确认配额用完

打开 vigolive 小程序 → 我的 → AI 接入 → 点击对应 key → 查看今日用量。

| 项目 | 免费配额 |
|------|---------|
| 搜索类工具 | 500 次/天/key |
| `get_contact_qrcode` | 50 次/天/key |
| 分钟突发 | 60 次/分钟 |

日配额按 key 独立计算，**次日 0 点（北京时间）**自动重置。

### 排查 3.2：分钟突发被触发

如果你在很短时间内（< 1 分钟）连续调用超过 60 次，会触发分钟突发限制。常见于：

- AI 编排循环里 bug，把 `search_houses` 循环调用
- 用户快速连续提问导致 AI 多次重试

等待 1 分钟后自动恢复。如果频繁触发，请检查 AI 是否在无效循环里。

### 排查 3.3：多 key 分流

如果你的使用量确实超过单 key 500 次/天，可以生成多把 key 分配给不同设备（`我的 Cursor` / `家里电脑 Claude` / `公司电脑 Claude Desktop`），账号级总配额会扩大。

### 排查 3.4：申请提额

批量或商用场景需要超出免费配额，请联系 vigolive 商务获取商用授权和扩容额度。

---

## 4. 工具调用超时 / 网络错误

**症状**：调用挂起很久后返回 `timeout` / `connection refused` / `network error`。

### 排查 4.1：MCP Server 可达性

```bash
curl -I https://mcp.vigolive.cn/mcp
```

期望返回 `200` 或 `405`（POST-only endpoint 对 HEAD 返回 405 也是正常）。

如果返回 `connection refused` / `SSL error`：

- 检查你的网络能否访问 `vigolive.cn`
- 检查 DNS 解析：`nslookup mcp.vigolive.cn`
- 如果在公司内网，联系网管放行 `*.vigolive.cn` 域名和 HTTPS 443 端口
- 如果在海外，某些线路可能访问大陆服务延迟较高，试试换网络环境

### 排查 4.2：AI 客户端超时设置

有些客户端对 MCP 工具调用有 10-30 秒的超时。vigo-mcp 的工具调用正常应该在 1-3 秒内返回，如果经常超时，可能是：

- 客户端问题（看客户端日志）
- 网络问题（见 4.1）

### 排查 4.3：单次调用太慢

`query_knowledge` 对某些长 query 可能会慢一些（RAG 检索）。如果延迟稳定在 5 秒左右，算正常。

如果 `search_houses` 也要 5 秒+，报 issue。

### 排查 4.4：`get_contact_qrcode` 失败

二维码接口依赖微信后端生成小程序码，偶尔会因为微信 API 限流或网络抖动失败。vigo-mcp 有 H5 短链兜底，但如果两个都失败会返回 error。重试一次通常能成功。

---

## 5. 其他问题

### "AI 说它看到了房东电话"

**绝不可能**。vigo-mcp 对所有响应做了**白名单脱敏**（代码层 + schema 层双保险），`McpHouse` 里根本没有 `publisherPhone` 字段。

如果 AI 给你报了一个"房东电话"，那是**幻觉**。请不要拨打（可能是随机编的，打过去也没用且侵犯陌生人），并告诉 AI："你看到的数据里没有房东电话，请用 get_contact_qrcode 返回二维码。"

### "AI 说这套房是自如/蛋壳/某某公寓的"

同样是**幻觉**。vigo-mcp 强制去品牌化，商家品牌字段从响应里被完全剔除。AI 不可能从工具响应里看到品牌名，如果说有，就是编的。

### 结果里没有我想要的城市

vigolive 当前主要覆盖北京、上海、深圳、广州、杭州等一线和新一线城市。其他城市可能数据较少或返回空结果。

### 结果是 0 条

- 把价格放宽（如 `price_max=6000` 改成 `price_max=8000`）
- 把通勤放宽（如 `30` → `45`）
- 去掉一些 `keywords` 过滤
- 换一个 `location`

AI 如果按 Skill 的"模式 E"正确工作，应当主动建议放宽。

---

## 报告问题

如果排查完还是不行，请带上以下信息报 GitHub Issue：

- 操作系统 + AI 工具 + 版本
- 完整错误信息（去掉 API Key）
- MCP 配置文件内容（**去掉 API Key**）
- 复现步骤
