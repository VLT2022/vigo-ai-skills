# 获取 vigolive API Key

vigo-mcp 的所有请求都需要一把 API Key 作 HTTP header（`X-API-Key`）。本页教你如何在 vigolive 小程序内自助生成。

---

## 前置条件

- 手机已安装微信
- 有 vigolive 账号（没有的话第一次进小程序会自动注册）

---

## 生成步骤（图文）

### 1. 打开 vigolive 小程序

微信 → 搜索 `vigolive` 或扫下方小程序码：

> 图片占位：`docs/images/mp-qrcode.png`
> *vigolive 微信小程序码*

如果是第一次使用，会自动走一次微信授权登录，不需要额外注册流程。

---

### 2. 进入「我的」→「AI 接入」

底部 tab 切到「我的」，找到「AI 接入」入口卡片（图标是机器人/齿轮）。

> 图片占位：`docs/images/mp-my-page.png`
> *「我的」页的 AI 接入卡片入口*

点击进入 AI 接入管理页。

---

### 3. 生成新 Key

页面上会显示当前已有的 key 列表（首次进来是空的）以及「+ 生成新的 API Key」按钮。每个账号**最多 5 把 active key**，建议为不同 AI 工具分别生成。

> 图片占位：`docs/images/mp-keys-empty.png`
> *AI 接入管理页首次进入*

点击「+ 生成新的 API Key」。

---

### 4. 填写用途说明

弹窗要求你填一个 `appName`，用于区分不同 key。命名建议直观，比如：

- `我的 Cursor`
- `公司电脑 Claude Desktop`
- `MacBook Claude Code`
- `测试用`

> 图片占位：`docs/images/mp-keys-create-modal.png`
> *创建弹窗：输入 appName*

点击「确定」。

---

### 5. 复制完整 Key（⚠️ 一次性）

生成后会弹一个**关键提示**页面，上面显示完整的 API Key，格式如：

```
vgk_live_a3f8b2c1d4e5f67890abcdef1234567
```

**这是唯一一次能看到完整 key 的机会**。关闭弹窗后列表里只会显示前 13 位（如 `vgk_live_a3f8`）用于辨识。

> 图片占位：`docs/images/mp-keys-show-full.png`
> *一次性显示完整 key + 大号复制按钮*

页面上有两个按钮：

- **「复制 Key」**：只复制 `vgk_live_xxx` 字符串本体
- **「复制完整 MCP 配置 JSON」**：复制可直接粘贴到 AI 工具配置文件的 JSON 片段，已经替换好 key

**推荐**点「复制完整 MCP 配置 JSON」，拿到类似下面的 JSON 直接粘到 Claude Desktop / Cursor 配置文件里：

```json
{
  "mcpServers": {
    "vigo-mcp": {
      "transport": "http",
      "url": "https://mcp.vigolive.cn/mcp",
      "headers": {
        "X-API-Key": "vgk_live_a3f8b2c1d4e5f67890abcdef1234567"
      }
    }
  }
}
```

---

### 6. 保存 Key

复制到剪贴板后：

- **粘贴到电脑**：通过微信「文件传输助手」把 key 发给自己，或直接在电脑端微信里复制
- **粘贴到 1Password / Bitwarden / Keychain 等密码管理器**：长期保存
- **⚠️ 不要**：截图保存（截图会泄漏）、发群聊、提交到 Git 仓库

然后按 [`how-to-install.md`](how-to-install.md) 把 key 写到对应 AI 工具的 MCP 配置文件里。

---

## 管理 Key

### 查看用量

在 AI 接入管理页，每张 key 卡片上会显示：

- `vgk_live_xxxx`（前 13 位）
- `appName`
- `今日 23/500`（今日调用 / 日配额）
- `上次使用：2 小时前`

> 图片占位：`docs/images/mp-keys-list-with-data.png`
> *有数据的 key 列表*

点击单张 key 可进入详情页，看最近 7 天的日调用量分布和按工具拆分的调用统计。

### 吊销 Key

在 key 卡片上点「吊销」按钮 → 确认。吊销后：

- 该 key 立即失效（Redis 缓存最多延迟 5 分钟同步到 vigo-mcp）
- 列表移除该 key，释放一个 active 名额
- 所有正在使用该 key 的 AI 工具会立即收到认证错误

**常见吊销场景**：

- Key 不小心泄漏（截图被人看到、推到 Git 仓库、发群聊）
- 某台设备不再使用
- 想"重置"配额（吊销旧 key + 重新生成新 key 并不能绕过日配额，配额按用户维度累计；但能清掉无效的 active 名额）

### 5 把 active key 上限

一个账号最多 5 把 active key。达到上限后要先吊销至少一把才能生成新的。

---

## 配额

| 项目 | 免费额度 |
|------|---------|
| 搜索类（search_houses / get_house_detail / search_by_commute / query_knowledge）| **500 次/天/key** |
| `get_contact_qrcode` | **50 次/天/key** |
| 分钟突发 | 60 次/分钟 |

**配额是按 key 维度独立计算**，不是按用户维度。如果你为 5 个工具各生成一把 key，理论上能拿到 5 × 500 = 2500 次搜索/天（但同一用户行为建议集中在一把 key 上，方便追踪和吊销）。

**超配额**：vigo-mcp 返回 JSON-RPC error `-32001`，AI 客户端会显示为"调用失败"。请等待次日 0 点自动重置。

---

## 安全建议

- **一键吊销**：发现 key 泄漏立即吊销
- **最小权限**：不要给非必要设备配 key
- **命名区分**：`appName` 写清楚是哪台设备哪个工具，方便追踪
- **定期审计**：在 AI 接入管理页看「上次使用」，长期未用的 key 可以吊销
- **不要公开仓库提交 key**：`vgk_live_` 前缀是明显标识，GitHub Secret Scanning 会识别并告警

---

## 遇到问题？

- Key 复制失败、弹窗闪退 → 联系 vigolive 客服
- 生成 key 报错 `MCP_KEY_LIMIT_REACHED` → 先吊销一把旧 key
- AI 工具连不上 → 见 [`troubleshooting.md`](troubleshooting.md)
