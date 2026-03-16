# Claude Code Remote Simple

A simplified fork of [Claude-Code-Remote](https://github.com/JessyTsui/Claude-Code-Remote) focused on **Telegram + tmux** workflow. Control Claude Code remotely from your phone — just send a message, get a clean reply. No tokens, no complex commands.

## What's Different from the Original

| Feature | Original | This Version |
|---------|----------|-------------|
| Send commands | `/cmd TOKEN command` | Just type your message |
| Notifications | Verbose (project, token, question, response, buttons) | Clean Claude response only |
| Multi-instance | All Claude instances trigger notifications | Only the designated tmux session triggers |
| Response content | Raw terminal output with UI artifacts | Filtered, clean text |
| Startup | Multiple manual steps | One-click `./start.sh` |

## Prerequisites

- **Node.js** >= 14.0.0
- **tmux** (`brew install tmux`)
- **ngrok** (`brew install ngrok`) with a [free account](https://ngrok.com)
- **terminal-notifier** (optional, for macOS desktop notifications: `brew install terminal-notifier`)

## Quick Start

### 1. Clone & Install

```bash
git clone https://github.com/YOUR_USERNAME/Claude-Code-Remote-Simple.git
cd Claude-Code-Remote-Simple
npm install
```

### 2. Create Telegram Bot

1. Open Telegram, search for `@BotFather`
2. Send `/newbot`, follow the prompts
3. Save the **Bot Token** you receive

### 3. Get Your Chat ID

Search for `@userinfobot` on Telegram, send it a message, it will reply with your Chat ID.

### 4. Configure

```bash
cp .env.example .env
```

Edit `.env` and fill in:

```env
TELEGRAM_BOT_TOKEN=your-bot-token
TELEGRAM_CHAT_ID=your-chat-id
TELEGRAM_WHITELIST=your-chat-id
SESSION_MAP_PATH=/full/path/to/Claude-Code-Remote-Simple/src/data/session-map.json
```

### 5. Configure ngrok

```bash
ngrok config add-authtoken YOUR_NGROK_AUTHTOKEN
```

### 6. Configure Claude Code Hooks

Add to `~/.claude/settings.json`:

```json
{
  "hooks": {
    "Stop": [
      {
        "matcher": "*",
        "hooks": [
          {
            "type": "command",
            "command": "if [ -n \"$TMUX\" ]; then node /full/path/to/Claude-Code-Remote-Simple/claude-hook-notify.js completed; fi",
            "timeout": 5
          }
        ]
      }
    ]
  }
}
```

> The `if [ -n "$TMUX" ]` check ensures only the Claude instance running inside tmux triggers notifications. Other Claude instances on your machine will not send Telegram messages.

### 7. Create Symlinks (macOS with Homebrew)

If you installed tmux and terminal-notifier via Homebrew on Apple Silicon:

```bash
sudo ln -sf /opt/homebrew/bin/tmux /usr/local/bin/tmux
sudo ln -sf /opt/homebrew/bin/terminal-notifier /usr/local/bin/terminal-notifier
```

This ensures hook scripts (which run via `/bin/sh`) can find these commands.

### 8. Launch

```bash
./start.sh
```

This one command will:
1. Create a tmux session named `claude-tel` and start Claude in it
2. Start ngrok tunnel (port 3001)
3. Automatically set the Telegram webhook URL
4. Start the webhook server

## Daily Usage

### Start everything
```bash
cd ~/Claude-Code-Remote-Simple && ./start.sh
```

### View Claude conversation
```bash
tmux attach -t claude-tel
```
Press `Ctrl+B` then `D` to detach (Claude keeps running).

### Send commands from Telegram
Just type your message to the bot. That's it.

### What you'll see
```
You: analyze this code for bugs

Bot: ✅ Claude-Code-Remote-Simple
     I've analyzed the code and found 3 potential issues...
```

## How It Works

```
┌──────────┐     ┌─────────┐     ┌──────────┐     ┌─────────────┐
│ Telegram │ ──> │  ngrok  │ ──> │ Webhook  │ ──> │ tmux:       │
│   App    │     │ tunnel  │     │ Server   │     │ claude-tel  │
│          │ <── │         │ <── │ (:3001)  │ <── │ (Claude)    │
└──────────┘     └─────────┘     └──────────┘     └─────────────┘
                                                        │
                                       Stop Hook ───────┘
                                  (only if $TMUX is set)
```

1. **You send a message** on Telegram
2. Telegram forwards it to your **ngrok** public URL
3. The **webhook server** receives it and injects the text into the **tmux session**
4. Claude processes it and responds in the terminal
5. When Claude stops, the **Stop hook** fires, captures the response from tmux
6. The response is sent back to you on **Telegram**

## Command Formats

All three formats are supported:

| Format | Example | Description |
|--------|---------|-------------|
| Direct message | `analyze this code` | Recommended. Injects directly to tmux |
| Token shorthand | `H6XFF125 analyze this code` | Uses session token |
| Full command | `/cmd H6XFF125 analyze this code` | Original format |

## Troubleshooting

### Telegram bot doesn't respond
- Check if ngrok is running: `curl http://127.0.0.1:4040/api/tunnels`
- Check if webhook server is running: `curl http://127.0.0.1:3001/health`
- Restart with `./start.sh`

### Duplicate notifications
- Make sure the hook in `settings.json` uses the `$TMUX` check
- Restart all Claude instances after changing `settings.json`

### "Tmux session not found" error
- Verify session exists: `tmux list-sessions`
- Session should be named `claude-tel`

### Response contains terminal artifacts
- The tmux-monitor filters most UI elements automatically
- If you see new artifacts, add filter patterns in `src/utils/tmux-monitor.js`

### ngrok URL changed after restart
- Run `./start.sh` again — it automatically re-sets the webhook URL

## Customization

### Change tmux session name

Edit these three places:
1. `start.sh` — change all `claude-tel` references
2. `src/channels/telegram/webhook.js` — line with `injectCommand(messageText, 'claude-tel')`
3. Rename existing session: `tmux rename-session -t old-name new-name`

### Adjust response length

In `src/channels/telegram/telegram.js`, find `substring(0, 500)` and change the limit.

## Credits

Based on [Claude-Code-Remote](https://github.com/JessyTsui/Claude-Code-Remote) by JessyTsui. Simplified for Telegram-only usage with cleaner notifications and direct messaging support.

## License

MIT
