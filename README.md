# vigo-ai-skills

> 让 Claude Desktop、Claude Code、Cursor、Windsurf、Codex CLI、OpenCode 等主流 AI 工具帮你找中国大陆的长租房源。

**vigolive** 是一家服务北上广深杭等主流城市的长租房源平台。本 repo 提供一个标准 Anthropic SKILL.md 格式的 Skill + 一键安装脚本，搭配 [vigolive MCP Server](https://mcp.vigolive.cn/mcp) 使用，让你在任意支持 MCP 的 AI 工具里说"帮我在上海陆家嘴找个 8000 以内的整租"就能拿到真实房源结果。

---

## 5 分钟接入

### 第 1 步：生成 API Key（1 分钟）

在手机上打开 **vigolive 小程序 →「我的」→「AI 接入」→「生成新的 API Key」**：

1. 给它起个名字（如"我的 Cursor"）
2. 复制生成的 `vgk_live_xxx` 开头的 key（**一次性显示**，关闭后无法再看完整值）
3. 保存好

详细图文步骤见 [`docs/api-key.md`](docs/api-key.md)。

### 第 2 步：一键安装（2 分钟）

```bash
git clone https://github.com/vigolive/vigo-ai-skills.git
cd vigo-ai-skills
./install.sh
```

脚本会自动：

- 检测你电脑上已安装的 AI 工具（Claude Code、Claude Desktop、Cursor、Codex CLI、OpenCode 等）
- 让你选择要安装到哪个（可多选）
- 把 `skills/vigo-find-house/` 复制到对应工具的 skills 目录
- 打印下一步操作（把 MCP 配置粘贴到配置文件 + 替换 API Key 占位符）

手动安装步骤见 [`docs/how-to-install.md`](docs/how-to-install.md)。

### 第 3 步：开始对话（2 分钟）

重启 AI 工具，试着说：

```
帮我在北京望京 SOHO 附近找 5000 以下整租，通勤 30 分钟内
```

AI 会自动识别需求 → 调用 `vigo-mcp.search_by_commute` → 返回表格化的房源列表。想看某套细节时说"第 2 套详细看看"，想联系房东时说"这套怎么联系"，AI 会返回一张二维码让你用微信扫码进 vigolive 小程序闭环。

---

## 兼容性矩阵

vigo-mcp 是远程 HTTP + SSE 服务，以下 AI 工具都能一次配置、直接使用：

| 客户端 | 厂商 | MCP 支持 | 传输 | vigo-mcp 可用 |
|--------|------|---------|------|-------------|
| Claude Desktop | Anthropic | ✅ 原生 | HTTP + SSE | ✅ |
| Claude Code | Anthropic | ✅ 原生 | HTTP + SSE + stdio | ✅ |
| Cursor | Cursor | ✅ 原生 | HTTP + SSE | ✅ |
| Windsurf | Codeium | ✅ 原生 | HTTP + SSE | ✅ |
| Cline / Roo Cline | 开源 | ✅ 原生 | HTTP + stdio | ✅ |
| Continue | 开源 | ✅ 原生 | stdio | ✅ |
| Zed | Zed Industries | ✅ 原生 | HTTP | ✅ |
| OpenCode / OpenClaw | 开源 | ✅ 原生 | HTTP + stdio | ✅ |
| Codex CLI | OpenAI | ✅ 原生 | HTTP + stdio | ✅ |
| ChatGPT Desktop | OpenAI | ⚠️ Plus/Pro plan 分阶段开放 | HTTP | ✅ |
| GitHub Copilot Chat | GitHub | 🔜 宣布中 | - | 🔜 |
| Gemini Code | Google | 🔜 宣布中 | - | 🔜 |
| 通义千问 / 文心一言 / Kimi | 中国厂商 | ❌ 暂不原生支持 | - | 🔧 需 LangChain 适配层 |

**结论**：一次配置，90% 的主流 AI 用户立刻可用。

---

## 可用工具

vigo-mcp 提供 5 个工具，在 Claude Code 等支持 slash command 的客户端里可直接手打调用：

| 工具 | 用途 | Slash command 示例 |
|------|------|--------------------|
| `search_houses` | 按城市/预算/户型搜索 | `/mcp__vigo-mcp__search_houses city="北京" price_max=6000 rent_type=1` |
| `get_house_detail` | 查看某套详情 | `/mcp__vigo-mcp__get_house_detail house_id="abc123"` |
| `search_by_commute` | 按通勤时间搜索 | `/mcp__vigo-mcp__search_by_commute city="北京" workplace="望京SOHO" max_commute_minutes=30` |
| `query_knowledge` | 查询小区背景/租房常识 | `/mcp__vigo-mcp__query_knowledge query="望京小区怎么样"` |
| `get_contact_qrcode` | 获取房源联系二维码（扫码进小程序） | `/mcp__vigo-mcp__get_contact_qrcode house_id="abc123"` |

或者直接用自然语言，AI 会通过 Skill 指引自主选择合适的工具。见 [`skills/vigo-find-house/examples.md`](skills/vigo-find-house/examples.md) 里的 5 个典型对话场景。

---

## API Key 配额

| 项目 | 免费额度 |
|------|---------|
| `search_houses` / `get_house_detail` / `search_by_commute` / `query_knowledge` | **500 次/天/key** |
| `get_contact_qrcode` | **50 次/天/key** |
| 分钟突发上限 | 60 次/分钟 |

- 超限返回 JSON-RPC error `-32001`，请等待次日重置或通过 vigolive 小程序直接使用 AI 找房
- 单用户最多持有 5 把 active key，可在小程序随时吊销旧 key
- 免费配额对大部分个人用户足够。批量商用接入请联系 vigolive 商务

---

## 隐私与合规

**vigolive MCP 永远不会返回任何联系方式和品牌信息**：

- ❌ 不返回房东姓名、电话、微信、头像
- ❌ 不返回管家联系方式
- ❌ 不返回公寓品牌、商家名称、apartmentName
- ✅ 返回去品牌化的房源本体信息（户型、价格、位置、图片、描述）
- ✅ 提供「扫码进小程序」的二维码作为唯一合规联系路径

这样设计是为了：
1. 保护房东个人隐私
2. 防止品牌信息被 AI 编造或误用
3. 把成交闭环落在 vigolive 小程序内，合规可追溯

**AI 不应该编造** MCP 没返回的字段。如果你发现 AI 给你报了一个房东电话，那一定是幻觉，请不要相信。

---

## 示例对话

完整的 5 个典型对话场景见 [`skills/vigo-find-house/examples.md`](skills/vigo-find-house/examples.md)：

1. 简单条件搜索
2. 通勤搜索
3. 多轮推进（search → detail → knowledge → qrcode）
4. 模糊需求澄清
5. 拒绝越界（不给联系方式 / 不编造品牌）

---

## FAQ

### Q: 我没装 MCP 客户端，只装了 Skill，能用吗？
**A**: 不能。Skill 只是"使用说明书"，真正的能力来自 MCP Server。没装 MCP 时，AI 看到 Skill 里的工具名却无法调用，会回退到幻觉或拒答。

### Q: 装了 MCP 客户端，但没装 Skill，能用吗？
**A**: 可以。你可以用 slash command 显式调用（`/mcp__vigo-mcp__search_houses ...`）或 @mention 让 AI 知道这个工具。装 Skill 只是让 AI 在自然语言场景下"更聪明地主动用"这些工具。

### Q: AI 没有触发 Skill / 不主动调 vigo-mcp，怎么办？
**A**: 见 [`docs/troubleshooting.md`](docs/troubleshooting.md)。常见原因是 Skill 路径不对或 description 里的关键词没匹配到。

### Q: API Key 泄漏了怎么办？
**A**: 立即去 vigolive 小程序「我的 →AI 接入」吊销该 key，然后生成一把新的。吊销后 Redis 缓存会在 5 分钟内全网生效。

### Q: 配额不够用怎么办？
**A**: 免费版配额足够个人日常使用。批量或商用场景请联系 vigolive 商务申请提额。

### Q: 能否在一个账号下给多个工具分别配 key？
**A**: 可以。一个账号最多 5 把 active key，建议为每个 AI 工具分别生成一把（"我的 Cursor"、"我的 Claude Desktop"、"公司电脑 Claude Code"），方便追踪和独立吊销。

### Q: 小程序端看到的房源和 MCP 看到的有什么区别？
**A**: MCP 是**规则搜索**（按条件过滤），小程序是**AI 个性化推荐**（基于用户画像主动找房）。想要 AI 深度推荐，请用 vigolive 小程序内的 AI 找房功能。

### Q: 支持哪些城市？
**A**: 北京、上海、深圳、广州、杭州等 vigolive 已开通的主流城市。未开通城市可能返回 0 结果。

### Q: 可以商用吗？
**A**: 个人和小规模集成欢迎。商用请联系 vigolive 商务（见官网）获取商用授权。

---

## 链接

- **vigolive 官网**：https://vigolive.cn
- **vigolive 小程序**：微信搜索"vigolive"
- **vigo-mcp Server**：https://mcp.vigolive.cn/mcp
- **问题反馈**：GitHub Issues（迁移到独立 repo 后）
- **MCP 协议**：https://modelcontextprotocol.io

## License

MIT — 见 [`LICENSE`](LICENSE)
