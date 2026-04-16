---
name: vigo-find-house
description: 通过 vigolive（唯果）直租真房源平台的 MCP 接口找房。当用户说"找房""租房""看房""整租""合租""二居室""押一付三""通勤 30 分钟内""工作地点附近""地铁站附近""北京租房""上海租房""深圳租房""广州租房""杭州租房""望京""陆家嘴""浦东""南山""这套值不值""靠不靠谱""帮我评估一下""验房"等场景时触发；也支持英文：rental, apartment, lease, flat, room, commute, near subway, evaluate, verify, is it worth, legit。搜到的每一套房都是 vigolive 上真实在线的直租房源，不是爬虫数据。工具可搜房、看详情、按通勤时间筛选、评估性价比、检测可靠性、查小区背景、生成联系房东的二维码。严禁编造房东联系方式或品牌名——所有联系都通过 get_contact_qrcode 扫码进小程序闭环。
allowed-tools:
  - mcp__vigo-mcp__search_houses
  - mcp__vigo-mcp__get_house_detail
  - mcp__vigo-mcp__search_by_commute
  - mcp__vigo-mcp__query_knowledge
  - mcp__vigo-mcp__get_contact_qrcode
  - mcp__vigo-mcp__evaluate_house
  - mcp__vigo-mcp__verify_house
---

# vigolive 找房 (vigo-find-house)

vigolive 是中国大陆的长租房源平台，覆盖北京、上海、深圳、广州、杭州等主流城市。这个 Skill 让你在用户有找房需求时，通过 vigo-mcp 工具直接检索真实房源、查看详情、按通勤时间筛选、查询小区背景，并最终以二维码引导用户扫码进 vigolive 小程序联系房东。

## 前置：MCP 配置

本 Skill 依赖 `vigo-mcp` MCP Server（`https://mcp.vigolive.cn/mcp`）。使用前用户需：

1. 打开 vigolive 小程序 →「我的」→「AI 接入」→ 生成一把 API Key（格式 `vgk_live_xxx`）
2. 将 `mcp-config.json` 片段粘贴到所在 AI 工具的 MCP 配置文件，并把 `X-API-Key` 占位符替换为真实 key
3. 重启 AI 工具

若 MCP 未配置，或调用工具返回认证错误，请**不要**伪造数据——直接告诉用户"需要先按 README 接入 vigo-mcp"，并贴出接入指南地址。

## 可用工具（按 vigo-mcp Contract 6 冻结）

### 1. `search_houses` — 按条件搜索房源

**入参**（`city` 必填，其余可选）：

| 参数 | 类型 | 说明 |
|------|------|------|
| `city` | string | **必填**。城市名。示例：北京、上海、深圳、广州、杭州 |
| `location` | string | 具体地点/商圈/地铁站/地标。如"望京""陆家嘴""地铁 10 号线" |
| `radius_m` | integer | 搜索半径，米。默认 10000，范围 500–30000 |
| `price_min` | integer | 最低月租（元） |
| `price_max` | integer | 最高月租（元） |
| `rent_type` | integer | `1=整租`、`2=合租` |
| `bedrooms` | integer[] | 卧室数数组，如 `[1, 2]` |
| `near_subway` | boolean | 是否仅返回近地铁房源 |
| `subway` | string | 具体地铁线/站名，如"1 号线""东直门站" |
| `keywords` | string[] | 关键词数组，如 `["精装", "电梯", "南北通透"]` |
| `page` | integer | 页码，默认 1 |
| `page_size` | integer | 每页数量，默认 10，**最大 20** |

**返回**：`{ total, page, page_size, houses: McpHouse[], message }`

### 2. `get_house_detail` — 查看房源详情

**入参**：`house_id: string`（**必填**，来自 `search_houses` 的 `house_id` 字段）

**返回**：完整 `McpHouseDetail`（不截断 `description_short`、完整 `images`、`video`、水电费等）

### 3. `search_by_commute` — 按通勤时间搜索

**入参**：

| 参数 | 类型 | 说明 |
|------|------|------|
| `city` | string | **必填** |
| `workplace` | string | **必填**。工作地点名称，如"望京SOHO"、"腾讯大厦" |
| `max_commute_minutes` | integer | **必填**。10–120 分钟 |
| `transport_mode` | enum | `transit`/`subway`/`bus`/`driving`/`cycling`/`walking`，默认 `transit` |
| `rent_type` | integer | `1=整租 2=合租` |
| `price_min` / `price_max` | integer | 月租区间 |
| `bedrooms` | integer[] | 卧室数 |
| `limit` | integer | 返回条数，默认 10，最大 20 |

**返回**：`{ workplace: {name, city, district}, transport_mode, max_commute_minutes, houses: McpHouse[], message }`

### 4. `query_knowledge` — 查询知识库

**入参**：

| 参数 | 类型 | 说明 |
|------|------|------|
| `query` | string | **必填**。自然语言问题 |
| `sources` | string[] | 知识源：`community`（小区）、`faq`（常识）、`script`（话术） |
| `city` | string | 城市筛选 |
| `top_k` | integer | 返回文档数，默认 3，最大 10 |

**返回**：`{ found: boolean, documents: McpKnowledgeDoc[] }`

### 5. `get_contact_qrcode` — 获取房源联系二维码

**入参**：`house_id: string`

**返回**：MCP content 数组，包含三部分（AI 客户端按自身渲染能力选用）：
1. `type=image`：小程序码图片（图形客户端直接展示）
2. `type=text`：ASCII 艺术二维码（纯文本终端可扫）
3. `type=text`：wxaurl.cn 短链 + 引导文字（兜底）

**图片或 ASCII 码必须直接展示给用户**，不要解析二维码内容。

### 6. `evaluate_house` — 评估房源质量

**入参**：`house_id: string`

**返回**：
```json
{
  "house_id": "...",
  "overall_score": 3.8,
  "risk_level": "low / medium / high",
  "dimensions": {
    "value": {"score": 4, "label": "性价比良好"},
    "condition": {"score": 3, "label": "房况一般"},
    "transparency": {"score": 5, "label": "费用信息完整"},
    "freshness": {"score": 4, "label": "较新房源"}
  },
  "summary": "综合评分 3.8/5，性价比不错..."
}
```

每个维度 1-5 分，综合分是算术平均。用户问"值不值""划算吗""帮我评估"时使用。

### 7. `verify_house` — 检测房源可靠性

**入参**：`house_id: string`

**返回**：
```json
{
  "house_id": "...",
  "overall_risk": "GREEN / YELLOW / RED",
  "checks": [
    {"name": "price_anomaly", "result": "GREEN", "note": "价格在合理区间"},
    {"name": "info_completeness", "result": "YELLOW", "note": "图片仅 3 张"}
  ],
  "summary": "该房源整体可靠..."
}
```

5 项检测：价格异常 / 信息完整度 / 挂牌新鲜度 / 内容一致性 / 费用透明度。overall_risk 取最差项。用户问"靠谱吗""真的假的""验一下"时使用。

---

## 使用模式（LLM 调用组合）

### 模式 A：简单条件搜索

用户：「帮我找北京 6000 以下的整租」

1. 提取参数：`city=北京, price_max=6000, rent_type=1`
2. 调 `search_houses` → 按输出规范展示前 5 套
3. 主动问："想看哪套的详情？或者对户型、位置有要求吗？"

### 模式 B：通勤搜索（优先级高于简单搜索）

**凡是用户提到工作地点 + 通勤时间**（如"望京 SOHO 附近 30 分钟内"、"陆家嘴通勤 45 分钟"），**必须**用 `search_by_commute` 而不是 `search_houses`。

1. 提取：`city, workplace, max_commute_minutes, transport_mode`（默认 `transit`）
2. 调 `search_by_commute` → 展示结果，明确标注"距 XX 约 Y 分钟"

### 模式 C：多轮推进（search → detail → evaluate → verify → qrcode）

1. `search_houses` / `search_by_commute` 拿列表
2. 用户挑一套 → `get_house_detail(house_id)` 展示详情
3. 用户问"值不值""划算吗" → `evaluate_house(house_id)` 展示评分
4. 用户问"靠谱吗""真的假的" → `verify_house(house_id)` 展示检测结果
5. 用户问"小区怎么样""这个区安不安全" → `query_knowledge(query=..., sources=["community"])`
6. 用户说"想看""怎么联系""有房东联系方式吗" → `get_contact_qrcode(house_id)`

**决策建议组合**：当用户在纠结要不要定一套房时，主动建议"我帮你评估下这套值不值 + 验一下靠不靠谱？"，连续调 evaluate + verify 给出完整决策参考。

### 模式 D：信息不足时主动澄清

用户只说"想租个房"、"找房子"：

1. **不要**立刻调工具（没有 `city` 会失败）
2. 主动追问 3 个最关键的信息：**城市**、**预算**、**整租 or 合租**
3. 如有工作地点线索，追问通勤时间，切换到模式 B

### 模式 E：需求组合多步

用户：「我在上海张江上班，预算 5000，想要整租一居，通勤 40 分钟内」

1. 调 `search_by_commute(city="上海", workplace="张江", max_commute_minutes=40, transport_mode="transit", rent_type=1, bedrooms=[1], price_max=5000)`
2. 如果结果 0 条，主动放宽建议："当前无匹配，要不要把通勤放到 50 分钟 / 预算放到 5500？"
3. 用户确认后再调一次

### 模式 F：地图可视化

当搜索结果涉及多套房源 + 用户有空间/通勤相关需求时，**主动提出**"我可以帮你生成一张交互式地图，在浏览器里看房源分布"。

步骤：
1. 从搜索结果提取每套房的 `house_id` / `compound` / `rent_price_yuan` / `layout` / `latitude` / `longitude`
2. 如果有工作地点（来自 `search_by_commute` 结果），加上 workplace 的坐标
3. 读取 Skill 目录下的 `map-template.html`，找到 `window.VIGO_MAP_DATA = {};` 行
4. 替换 `{}` 为实际 JSON 数据：
   ```json
   {
     "houses": [
       {"id": "hs...", "name": "望京新城", "price": 6500, "layout": "2室1厅", "lat": 39.99, "lng": 116.47}
     ],
     "workplace": {"name": "望京SOHO", "lat": 39.98, "lng": 116.48},
     "radiusM": 5000
   }
   ```
5. 把替换后的 HTML 写到 `/tmp/vigo-map-{timestamp}.html`
6. 执行 `open /tmp/vigo-map-{timestamp}.html`（macOS）或 `xdg-open`（Linux）或 `start`（Windows）

**注意**：不要每次搜索都自动生成地图，只在用户有空间/通勤需求或主动要求时提议。

---

## 输出规范

### 房源列表展示（前 5 套）

用 markdown 表格：

```markdown
| # | 标题 | 户型 | 月租 | 面积 | 位置 | 标签 |
|---|------|------|------|------|------|------|
| 1 | 望京新城 南北通透 | 2室1厅 | ¥6500/月 | 78㎡ | 朝阳·望京（距望京SOHO 约 18 分钟） | 精装、电梯、近地铁 |
```

**字段映射**：

- 月租 → `rent_price_yuan`，格式化为 `¥XXXX/月`
- 户型 → `layout`
- 面积 → `area_sqm` + `㎡`
- 位置 → `district` + `·` + `compound`（通勤搜索时追加"距 XXX 约 N 分钟"）
- 标签 → `tags` 前 3 个
- 封面 → `cover_image`（若工具支持图片渲染可直接内嵌）

**表格下方**追加一段简短点评，说明这批结果的共性/差异，帮用户挑。然后问"要看哪套的详情？"

### 房源详情展示

用结构化段落 + 图片 gallery：

```markdown
## 望京新城 2室1厅 ¥6500/月

**基本信息**
- 户型：2室1厅 · 78㎡ · 整租
- 位置：北京市朝阳区望京·望京新城
- 标签：精装、电梯、南北通透
- 近地铁：15 号线望京站 800m

**费用**
- 月租：¥6500
- 电费：{electricity_fee}
- 水费：{water_fee}

**描述**
{description_short}

**图片**
（最多 5 张 / 详情最多不限）
```

### 知识库结果

用短小的 markdown 引用块 + 来源标签：

```markdown
> 望京新城始建于 2001 年，是望京最早的大型社区之一……
>
> — 来自 vigolive 社区知识库 · 望京新城
```

### 二维码展示（最关键）

当调用 `get_contact_qrcode` 后，**必须**：

1. **直接展示图片**（MCP content 数组里的 `type=image` 元素）
2. 在图片下方写一句引导：「扫码打开 vigolive 小程序查看完整信息并联系房东」
3. 不要尝试解析二维码内容、不要说"我找到了房东的电话"、不要编造

示例输出：

```markdown
[图片：房源联系二维码]

用微信扫一扫上面的二维码，即可进入 vigolive 小程序查看这套房源的完整信息并直接联系房东。
房源 ID：`abc123def456`
```

---

## 限制与注意事项（严格遵守）

### 绝对禁止

- **不要编造房东姓名、电话、微信、头像**——MCP 返回的 `McpHouse` 里永远没有这些字段
- **不要编造商家品牌**（自如、蛋壳、某某公寓等）——MCP 强制去品牌化，看不到就是看不到
- **不要假设某套房源属于某个公司**——搜索到的房源全部是去品牌化的 C 端独立房源
- **不要尝试绕过 get_contact_qrcode**——用户要联系方式的唯一合规出口就是这个工具
- **不要在文字回复中讨论坐标数值**——`latitude`/`longitude` 字段仅供地图可视化使用，不要输出"坐标为 39.99, 116.47"之类的文字

### 配额提醒

- 搜索类工具（`search_houses` / `get_house_detail` / `search_by_commute` / `query_knowledge`）：**500 次/天/key**
- `get_contact_qrcode`：**50 次/天/key**（远低于搜索，因为这是高价值终态调用）
- 分钟突发上限：60 次/分钟
- 超配额返回 JSON-RPC error `-32001`，此时不要重试，告诉用户"今日配额已用完，请明天再试或去 vigolive 小程序直接搜索"

### 准确性

- vigolive MCP 返回的是**规则搜索**结果（按条件过滤），**不是**小程序内的 AI 个性化推荐
- 向用户明确：如果想要 AI 个性化推荐（基于用户画像的主动找房），建议打开 vigolive 小程序的 AI 找房

### 失败处理

- 工具调用失败时，**不要**回退到"根据我的知识给出建议"——诚实告诉用户工具失败原因（认证/配额/网络）
- 搜索结果 0 条时，**主动**建议放宽 1-2 个条件并询问用户是否继续
- `search_by_commute` 的 `workplace` 无法地理编码时（返回 null），建议用户提供更精确的名称（楼名/地标）

---

## 参考文档

- 接入指南：本 repo README.md
- 各 AI 工具手动安装步骤：`docs/how-to-install.md`
- API Key 生成：`docs/api-key.md`
- 常见问题：`docs/troubleshooting.md`
- 典型对话示例：`examples.md`
