#!/bin/bash
# Claude Code Remote 一键启动脚本

cd "$(dirname "$0")"

echo "🚀 Starting Claude Code Remote..."

# 1. 确保 tmux 会话存在并运行 Claude
if /opt/homebrew/bin/tmux has-session -t claude-tel 2>/dev/null; then
    echo "✅ tmux session 'claude-tel' already running"
else
    echo "📺 Creating tmux session and starting Claude..."
    /opt/homebrew/bin/tmux new-session -d -s claude-tel
    /opt/homebrew/bin/tmux send-keys -t claude-tel 'claude' Enter
    echo "✅ Claude started in tmux session 'claude-tel'"
fi

# 2. 启动 ngrok（如果没在运行）
if curl -s http://127.0.0.1:4040/api/tunnels > /dev/null 2>&1; then
    echo "✅ ngrok already running"
else
    echo "🌐 Starting ngrok..."
    /opt/homebrew/bin/ngrok http 3001 --log=stdout --log-format=logfmt > /dev/null 2>&1 &
    sleep 3
fi

# 获取 ngrok 公网 URL
NGROK_URL=$(curl -s http://127.0.0.1:4040/api/tunnels | python3 -c "import json,sys; d=json.load(sys.stdin); print(d['tunnels'][0]['public_url'])" 2>/dev/null)

if [ -z "$NGROK_URL" ]; then
    echo "❌ Failed to get ngrok URL"
    exit 1
fi

echo "✅ ngrok URL: $NGROK_URL"

# 3. 设置 Telegram webhook
source .env
WEBHOOK_RESULT=$(curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/setWebhook" -d "url=${NGROK_URL}/webhook/telegram")
echo "✅ Telegram webhook set"

# 4. 启动 webhook 服务
echo "📱 Starting Telegram webhook server..."
echo ""
echo "========================================="
echo "  All services started!"
echo "  ngrok URL: $NGROK_URL"
echo "  tmux session: claude-tel"
echo "  Press Ctrl+C to stop webhook server"
echo "========================================="
echo ""

npm run telegram
