# ADR-20251210: 独自ドメイン（mitadake.com）の導入

## ステータス

Accepted

## コンテキスト

mitadake?サービスのブランディング強化と信頼性向上のため、独自ドメインを導入する。現在は `mvp-hello-world.onrender.com` でサービスを提供しているが、本番運用に向けて独自ドメインが必要となった。

### 導入の動機

1. **ブランディング**: サービス名と一致したドメインでユーザーの認知度向上
2. **信頼性**: 独自ドメインによるプロフェッショナルな印象
3. **SEO**: 独自ドメインによる検索エンジン最適化

## 決定

### 1. ドメイン取得

- **ドメイン**: mitadake.com
- **レジストラ**: お名前.com
- **選定理由**:
  - 日本語の管理画面・サポート
  - 国内での情報が豊富でトラブルシューティングしやすい
  - 価格が手頃

### 2. DNS設定

| レコードタイプ | ホスト名 | 値 |
|---------------|---------|-----|
| A | @ | 216.24.57.1 |
| CNAME | www | mvp-hello-world.onrender.com |

- RenderのIPアドレス（216.24.57.1）へのAレコード
- wwwサブドメインはRenderアプリへのCNAME

### 3. メインURL

- **推奨URL**: `https://www.mitadake.com`
- **理由**: wwwサブドメインを使用することで、CDNやロードバランサーの設定が柔軟に行える

### 4. Rails設定

```ruby
# config/environments/production.rb

# 許可するホスト
config.hosts = [
  "mitadake.com",
  "www.mitadake.com",
  "mvp-hello-world.onrender.com" # 移行期間中は残す
]

# メール内リンクのホスト
config.action_mailer.default_url_options = { host: "www.mitadake.com" }
```

## 移行時の注意事項

### Google OAuth設定

Google Cloud Consoleで以下の設定を手動で更新する必要がある：

1. [Google Cloud Console](https://console.cloud.google.com/) にアクセス
2. プロジェクトを選択
3. 「APIとサービス」→「認証情報」
4. OAuth 2.0クライアントIDを編集
5. 以下を追加：
   - **承認済みのJavaScript生成元**:
     - `https://www.mitadake.com`
     - `https://mitadake.com`
   - **承認済みのリダイレクトURI**:
     - `https://www.mitadake.com/users/auth/google_oauth2/callback`
     - `https://mitadake.com/users/auth/google_oauth2/callback`

### 移行期間

- 旧URL（mvp-hello-world.onrender.com）は当面の間アクセス可能に維持
- DNS反映完了後、動作確認してから旧URLを段階的に廃止

## 影響

### 影響を受けるファイル

- `config/environments/production.rb`

### 外部サービスの設定変更

- Google OAuth（手動で設定変更が必要）
- Render Custom Domain（設定済み）

## 代替案

### 案1: 別のレジストラを使用

- **Cloudflare Registrar**: 価格が安いが、英語のみ
- **Google Domains**: 廃止されSquarespaceに移行

→ 日本語サポートと情報の豊富さを優先し、お名前.comを採用

### 案2: wwwなしをメインURLに

- メリット: 短いURL
- デメリット: CDN設定時の柔軟性が低い

→ 運用の柔軟性を考慮し、wwwありを採用

## 日付

2025-12-10
