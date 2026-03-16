# Claude Code Remote Simple

[English](./README.md) | [中文](./README_CN.md) | [日本語](./README_JA.md)

[Claude-Code-Remote](https://github.com/JessyTsui/Claude-Code-Remote) をシンプルにしたフォーク版。**Telegram + tmux** ワークフローに特化。スマホから Claude Code をリモート操作 — メッセージを送るだけで、クリーンな返答が届きます。トークン不要、複雑なコマンド不要。

## オリジナル版との違い

| 機能 | オリジナル | 本バージョン |
|------|-----------|-------------|
| コマンド送信 | `/cmd TOKEN コマンド` | メッセージを直接送るだけ |
| 通知内容 | 冗長（プロジェクト名、トークン、質問、回答、ボタン） | Claude の回答のみ |
| マルチインスタンス | 全 Claude インスタンスが通知を発火 | 指定した tmux セッションのみ |
| レスポンス内容 | ターミナル UI 要素を含む | フィルター済みのクリーンテキスト |
| 起動方法 | 複数の手動ステップ | ワンクリック `./start.sh` |

## 前提条件

- **Node.js** >= 14.0.0
- **tmux** (`brew install tmux`)
- **ngrok** (`brew install ngrok`) [無料アカウント](https://ngrok.com) が必要
- **terminal-notifier**（オプション、macOS デスクトップ通知用：`brew install terminal-notifier`）

## クイックスタート

### 1. クローンとインストール

```bash
git clone https://github.com/sunxvecong/Claude-Code-Remote-Simple.git
cd Claude-Code-Remote-Simple
npm install
```

### 2. Telegram Bot を作成

1. Telegram で `@BotFather` を検索
2. `/newbot` を送信し、指示に従う
3. 受け取った **Bot Token** を保存

### 3. Chat ID を取得

Telegram で `@userinfobot` を検索し、メッセージを送ると Chat ID が返ってきます。

### 4. 設定

```bash
cp .env.example .env
```

`.env` を編集して以下を記入：

```env
TELEGRAM_BOT_TOKEN=あなたのbot-token
TELEGRAM_CHAT_ID=あなたのchat-id
TELEGRAM_WHITELIST=あなたのchat-id
SESSION_MAP_PATH=/フルパス/Claude-Code-Remote-Simple/src/data/session-map.json
```

### 5. ngrok を設定

```bash
ngrok config add-authtoken あなたのNGROK_AUTHTOKEN
```

### 6. Claude Code Hooks を設定

`~/.claude/settings.json` に追加：

```json
{
  "hooks": {
    "Stop": [
      {
        "matcher": "*",
        "hooks": [
          {
            "type": "command",
            "command": "if [ -n \"$TMUX\" ]; then node /フルパス/Claude-Code-Remote-Simple/claude-hook-notify.js completed; fi",
            "timeout": 5
          }
        ]
      }
    ]
  }
}
```

> `if [ -n "$TMUX" ]` により、tmux 内で実行されている Claude のみが通知をトリガーします。マシン上の他の Claude インスタンスは Telegram メッセージを送信しません。

### 7. シンボリックリンクを作成（macOS + Homebrew）

Apple Silicon Mac で Homebrew を使って tmux と terminal-notifier をインストールした場合：

```bash
sudo ln -sf /opt/homebrew/bin/tmux /usr/local/bin/tmux
sudo ln -sf /opt/homebrew/bin/terminal-notifier /usr/local/bin/terminal-notifier
```

Hook スクリプトは `/bin/sh` 経由で実行されるため、これらのコマンドを見つけられるようにする必要があります。

### 8. 起動

```bash
./start.sh
```

このコマンド1つで自動的に：
1. `claude-tel` という名前の tmux セッションを作成し、Claude を起動
2. ngrok トンネルを開始（ポート 3001）
3. Telegram webhook URL を自動設定
4. Webhook サーバーを起動

## 日常的な使い方

### すべてを起動
```bash
cd ~/Claude-Code-Remote-Simple && ./start.sh
```

### Claude の会話を確認
```bash
tmux attach -t claude-tel
```
`Ctrl+B` を押してから `D` でデタッチ（Claude は動き続けます）。

### Telegram からコマンドを送信
Bot にメッセージを送るだけです。

### 表示例
```
あなた: このコードのバグを分析して

Bot: ✅ Claude-Code-Remote-Simple
     コードを分析し、3つの潜在的な問題を発見しました...
```

## 仕組み

```
┌──────────┐     ┌─────────┐     ┌──────────┐     ┌─────────────┐
│ Telegram │ ──> │  ngrok  │ ──> │ Webhook  │ ──> │ tmux:       │
│   App    │     │ トンネル  │     │ サーバー  │     │ claude-tel  │
│          │ <── │         │ <── │ (:3001)  │ <── │ (Claude)    │
└──────────┘     └─────────┘     └──────────┘     └─────────────┘
                                                        │
                                       Stop Hook ───────┘
                                  ($TMUX が設定されている場合のみ)
```

1. **Telegram** でメッセージを送信
2. Telegram が **ngrok** の公開 URL に転送
3. **Webhook サーバー** が受信し、テキストを **tmux セッション** に注入
4. Claude がリクエストを処理し、ターミナルで応答
5. Claude が完了すると、**Stop hook** が発火し、tmux から応答をキャプチャ
6. 応答が **Telegram** 経由で送信される

## コマンド形式

3つの形式すべてに対応：

| 形式 | 例 | 説明 |
|------|---|------|
| ダイレクトメッセージ | `このコードを分析して` | 推奨。tmux に直接注入 |
| トークン省略形 | `H6XFF125 このコードを分析して` | セッショントークンを使用 |
| フルコマンド | `/cmd H6XFF125 このコードを分析して` | オリジナル形式 |

## トラブルシューティング

### Telegram Bot が応答しない
- ngrok が動いているか確認：`curl http://127.0.0.1:4040/api/tunnels`
- Webhook サーバーが動いているか確認：`curl http://127.0.0.1:3001/health`
- `./start.sh` で再起動

### 通知が重複する
- `settings.json` の hook で `$TMUX` チェックが使われていることを確認
- `settings.json` 変更後、すべての Claude インスタンスを再起動

### "Tmux session not found" エラー
- セッションの存在を確認：`tmux list-sessions`
- セッション名は `claude-tel` であること

### レスポンスにターミナル要素が含まれる
- tmux-monitor が自動的にほとんどの UI 要素をフィルタリングします
- 新しいアーティファクトが見つかった場合、`src/utils/tmux-monitor.js` にフィルターパターンを追加

### ngrok URL が再起動後に変わった
- `./start.sh` を再実行するだけ — webhook URL を自動的に再設定します

## カスタマイズ

### tmux セッション名を変更

3箇所を編集：
1. `start.sh` — `claude-tel` の参照をすべて変更
2. `src/channels/telegram/webhook.js` — `injectCommand(messageText, 'claude-tel')` の行
3. 既存セッションをリネーム：`tmux rename-session -t 旧名前 新名前`

### レスポンスの長さを調整

`src/channels/telegram/telegram.js` で `substring(0, 500)` を見つけて数値を変更。

## クレジット

JessyTsui の [Claude-Code-Remote](https://github.com/JessyTsui/Claude-Code-Remote) をベースに、Telegram 専用にシンプル化。クリーンな通知とダイレクトメッセージ対応。

## ライセンス

MIT
