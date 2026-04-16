# vigo-ai-skills

> 在 Claude / Cursor 里直接搜 vigolive 的直租真房源。

[vigolive（唯果）](https://vigolive.cn) 是一个直租找房平台，房源都是房东直发、平台审核的真实在线房源，覆盖北京、上海、深圳、广州、杭州等城市。

这个 repo 是 vigolive 的 **AI 找房 Skill**——装上之后，你在 Claude Code、Cursor、Windsurf 等 AI 工具里说一句"帮我在望京找个 6000 以下的整租"，AI 就会自动调用 vigolive 的接口帮你搜房、看详情、评估性价比、检测可靠性，最后生成一个二维码让你扫码直接进小程序联系房东。

**不是爬虫，不是模拟数据**——搜到的每一套房都是 vigolive 平台上真实在线的直租房源。

---

## 快速开始

### 1. 拿一把 API Key

打开微信搜 **vigolive 小程序 →「我的」→「MCP 连接」→ 生成 API Key**，复制 `vgk_live_xxx` 开头的 key（只显示一次）。

### 2. 安装 Skill

```bash
git clone https://github.com/VLT2022/vigo-ai-skills.git
cd vigo-ai-skills
./install.sh
```

脚本会自动检测你电脑上的 AI 工具，把 Skill 文件复制到对应目录。

### 3. 配置 MCP

把下面的配置粘到你 AI 工具的 MCP 配置文件里，`X-API-Key` 换成你的 key：

```json
{
  "mcpServers": {
    "vigo-mcp": {
      "transport": "http",
      "url": "https://mcp.vigolive.cn/mcp",
      "headers": { "X-API-Key": "vgk_live_你的key" }
    }
  }
}
```

重启 AI 工具，试试说"帮我在北京望京找 5000 以下整租，通勤 30 分钟内"。

---

## 能做什么

7 个工具，覆盖找房全流程：

| 工具 | 干嘛用的 |
|------|---------|
| `search_houses` | 按城市/预算/户型/地铁搜房 |
| `get_house_detail` | 看某套房的详细信息 |
| `search_by_commute` | 按通勤时间搜（比如"望京 SOHO 30 分钟内"）|
| `query_knowledge` | 问小区背景、租房常识 |
| `evaluate_house` | 评估一套房值不值（性价比/房况/透明度/时效 4 维评分）|
| `verify_house` | 验一套房靠不靠谱（价格异常/信息完整度/挂牌时长等 5 项检测）|
| `get_contact_qrcode` | 生成联系房东的二维码（扫码进 vigolive 小程序）|

你也可以不用自然语言，直接 slash command 调：

```
/mcp__vigo-mcp__search_houses city="北京" price_max=6000 rent_type=1
/mcp__vigo-mcp__evaluate_house house_id="hs4094008ac7774611"
```

装了 Skill 之后 AI 会更聪明：自动识别"找房"意图、按通勤优先级选工具、用表格展示结果、纠结时主动建议评估+验房。不装也能用 MCP，但体验差一点。

---

## 支持的 AI 工具

基本上主流的都支持：Claude Desktop、Claude Code、Cursor、Windsurf、Codex CLI、Cline、Continue、Zed、OpenCode。ChatGPT Desktop 也在陆续开放 MCP 支持。

完整兼容列表见 [docs/how-to-install.md](docs/how-to-install.md)。

---

## 配额

| | 免费额度 |
|---|---------|
| 搜索/详情/评估/验房/知识库 | 30 次/天/key |
| 联系二维码 | 30 次/天/key |

一个账号最多 5 把 key，每把独立计数。超了明天自动重置，也可以去小程序里直接搜。

---

## 示例对话

[examples.md](skills/vigo-find-house/examples.md) 里有 8 个完整对话场景，从简单搜索到全流程决策（搜房 → 看详情 → 评估 → 验房 → 联系管家）都有。

## License

MIT
