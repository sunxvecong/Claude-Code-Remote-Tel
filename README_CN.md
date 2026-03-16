# Claude Code Remote Simple

[English](./README.md) | [中文](./README_CN.md) | [日本語](./README_JA.md)

基于 [Claude-Code-Remote](https://github.com/JessyTsui/Claude-Code-Remote) 的精简版，专注于 **Telegram + tmux** 工作流。用手机远程控制 Claude Code — 直接发消息，收到干净的回复。无需 token，无需复杂命令。

## 与原版的区别

| 功能 | 原版 | 本版本 |
|------|------|--------|
| 发送命令 | `/cmd TOKEN 命令` | 直接发消息即可 |
| 通知内容 | 冗长（项目名、token、问题、回复、按钮） | 仅 Claude 回复 |
| 多实例 | 所有 Claude 实例都触发通知 | 仅指定的 tmux 会话触发 |
| 回复内容 | 包含终端 UI 元素 | 过滤后的干净文本 |
| 启动方式 | 多步手动操作 | 一键 `./start.sh` |

## 前置要求

- **Node.js** >= 14.0.0
- **tmux** (`brew install tmux`)
- **ngrok** (`brew install ngrok`) 需要 [免费账号](https://ngrok.com)
- **terminal-notifier**（可选，macOS 桌面通知：`brew install terminal-notifier`）

## 快速开始

### 1. 克隆并安装

```bash
git clone https://github.com/sunxvecong/Claude-Code-Remote-Simple.git
cd Claude-Code-Remote-Simple
npm install
```

### 2. 创建 Telegram Bot

1. 打开 Telegram，搜索 `@BotFather`
2. 发送 `/newbot`，按提示操作
3. 保存收到的 **Bot Token**

### 3. 获取你的 Chat ID

在 Telegram 搜索 `@userinfobot`，给它发条消息，它会回复你的 Chat ID。

### 4. 配置

```bash
cp .env.example .env
```

编辑 `.env`，填入：

```env
TELEGRAM_BOT_TOKEN=你的bot-token
TELEGRAM_CHAT_ID=你的chat-id
TELEGRAM_WHITELIST=你的chat-id
SESSION_MAP_PATH=/完整路径/Claude-Code-Remote-Simple/src/data/session-map.json
```

### 5. 配置 ngrok

```bash
ngrok config add-authtoken 你的NGROK_AUTHTOKEN
```

### 6. 配置 Claude Code Hooks

在 `~/.claude/settings.json` 中添加：

```json
{
  "hooks": {
    "Stop": [
      {
        "matcher": "*",
        "hooks": [
          {
            "type": "command",
            "command": "if [ -n \"$TMUX\" ]; then node /完整路径/Claude-Code-Remote-Simple/claude-hook-notify.js completed; fi",
            "timeout": 5
          }
        ]
      }
    ]
  }
}
```

> `if [ -n "$TMUX" ]` 确保只有在 tmux 中运行的 Claude 才会触发通知。你机器上其他 Claude 实例不会发送 Telegram 消息。

### 7. 创建软链接（macOS + Homebrew）

如果你在 Apple Silicon Mac 上通过 Homebrew 安装了 tmux 和 terminal-notifier：

```bash
sudo ln -sf /opt/homebrew/bin/tmux /usr/local/bin/tmux
sudo ln -sf /opt/homebrew/bin/terminal-notifier /usr/local/bin/terminal-notifier
```

这是因为 hook 脚本通过 `/bin/sh` 运行，需要确保它能找到这些命令。

### 8. 启动

```bash
./start.sh
```

这一条命令会自动：
1. 创建名为 `claude-tel` 的 tmux 会话并启动 Claude
2. 启动 ngrok 隧道（端口 3001）
3. 自动设置 Telegram webhook URL
4. 启动 webhook 服务

## 日常使用

### 启动所有服务
```bash
cd ~/Claude-Code-Remote-Simple && ./start.sh
```

### 查看 Claude 对话
```bash
tmux attach -t claude-tel
```
按 `Ctrl+B` 然后按 `D` 退出（Claude 继续运行）。

### 从 Telegram 发送命令
直接给 Bot 发消息就行。

### 你会看到
```
你: 分析这段代码有没有 bug

Bot: ✅ Claude-Code-Remote-Simple
     我分析了代码，发现了 3 个潜在问题...
```

## 工作原理

```
┌──────────┐     ┌─────────┐     ┌──────────┐     ┌─────────────┐
│ Telegram │ ──> │  ngrok  │ ──> │ Webhook  │ ──> │ tmux:       │
│   App    │     │  隧道    │     │  服务器   │     │ claude-tel  │
│          │ <── │         │ <── │ (:3001)  │ <── │ (Claude)    │
└──────────┘     └─────────┘     └──────────┘     └─────────────┘
                                                        │
                                       Stop Hook ───────┘
                                  (仅当 $TMUX 存在时)
```

1. 你在 **Telegram** 上发送消息
2. Telegram 转发到你的 **ngrok** 公网 URL
3. **Webhook 服务器** 接收并将文本注入 **tmux 会话**
4. Claude 处理请求并在终端响应
5. Claude 完成时，**Stop hook** 触发，从 tmux 抓取回复
6. 回复通过 **Telegram** 发送给你

## 命令格式

支持三种格式：

| 格式 | 示例 | 说明 |
|------|------|------|
| 直接发消息 | `分析这段代码` | 推荐。直接注入 tmux |
| Token 简写 | `H6XFF125 分析这段代码` | 使用会话 token |
| 完整命令 | `/cmd H6XFF125 分析这段代码` | 原版格式 |

## 常见问题

### Telegram Bot 没有回复
- 检查 ngrok 是否运行：`curl http://127.0.0.1:4040/api/tunnels`
- 检查 webhook 服务是否运行：`curl http://127.0.0.1:3001/health`
- 用 `./start.sh` 重启

### 收到重复通知
- 确保 `settings.json` 中的 hook 使用了 `$TMUX` 检查
- 修改 `settings.json` 后需要重启所有 Claude 实例

### "Tmux session not found" 错误
- 确认会话存在：`tmux list-sessions`
- 会话名应该是 `claude-tel`

### 回复包含终端 UI 元素
- tmux-monitor 会自动过滤大部分 UI 元素
- 如果看到新的异常内容，在 `src/utils/tmux-monitor.js` 中添加过滤规则

### ngrok URL 重启后变了
- 重新运行 `./start.sh` 即可 — 它会自动重新设置 webhook URL

## 自定义

### 修改 tmux 会话名

需要修改三个地方：
1. `start.sh` — 修改所有 `claude-tel` 引用
2. `src/channels/telegram/webhook.js` — `injectCommand(messageText, 'claude-tel')` 这一行
3. 重命名现有会话：`tmux rename-session -t 旧名称 新名称`

### 调整回复长度

在 `src/channels/telegram/telegram.js` 中，找到 `substring(0, 500)` 修改数值。

## 致谢

基于 JessyTsui 的 [Claude-Code-Remote](https://github.com/JessyTsui/Claude-Code-Remote)。为 Telegram 专用场景做了精简，支持更干净的通知和直接消息模式。

## 许可证

MIT
