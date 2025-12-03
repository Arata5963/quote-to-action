# ADR-20251203: YouTube API連携

## ステータス
承認済み

## コンテキスト
ActionSparkアプリでYouTube動画に紐づく投稿の検索性を向上させるため、YouTube Data API v3を使用して動画のタイトル・チャンネル名を自動取得する機能を実装する。

### 現状
- 投稿にはYouTube URL（`youtube_url`）が必須
- オートコンプリート検索は`trigger_content`, `action_plan`のみが対象
- 動画のタイトルやチャンネル名での検索ができない

### 要件
- YouTube URLから動画タイトル・チャンネル名を自動取得
- Post作成/更新時に取得処理を実行
- オートコンプリートの検索対象に追加
- 既存データの一括更新が可能

## 決定

### 実装パターン
**google-apis-youtube_v3（公式gem）** を採用する。

### 選択理由
| 観点 | 評価 |
|------|------|
| 参考記事 | ◎ Qiita/Zenn等で日本語記事多数 |
| エラーハンドリング | ◎ 例外クラスが豊富で扱いやすい |
| 公式サポート | ◎ Google公式メンテナンス |
| 型の安全性 | ○ レスポンスオブジェクトが型付き |
| 導入の手軽さ | ○ gemインストールのみ |

### 不採用案
- **直接HTTPリクエスト（Faraday）**: シンプルだが参考情報が少なく、レスポンスパース処理を自前実装する必要がある
- **yt gem**: YouTubeのみ対応だが、メンテナンスが不安定

### DBスキーマ
postsテーブルに以下のカラムを追加:
- `youtube_title` (string, null許可)
- `youtube_channel_name` (string, null許可)

### 取得タイミング
- Post作成時（create）に自動取得
- Post更新時（update）に`youtube_url`が変更された場合のみ取得

### API使用量の考慮
- YouTube Data API v3の無料枠: 10,000クォータ/日
- videos.list呼び出し: 1クォータ/リクエスト
- 現在の想定使用量で十分対応可能

## 実装計画

### ファイル構成
```
app/
├── models/
│   └── post.rb                    # コールバック追加
└── services/
    └── youtube_service.rb         # YouTube API呼び出し

config/
└── initializers/
    └── youtube.rb                 # API初期化

lib/
└── tasks/
    └── youtube.rake               # バッチ処理タスク

spec/
├── services/
│   └── youtube_service_spec.rb    # サービステスト
├── models/
│   └── post_spec.rb               # モデルテスト（追記）
└── requests/
    └── posts_spec.rb              # オートコンプリートテスト（追記）
```

### YoutubeServiceの責務
1. YouTube URLからvideo_idを抽出
2. YouTube Data API v3を呼び出し
3. タイトル・チャンネル名を返却
4. エラーハンドリング（無効URL、API制限、ネットワークエラー）

### エラーハンドリング方針
| エラー種別 | 対応 |
|-----------|------|
| 無効なURL | nil を返却、投稿は保存可能 |
| 動画が存在しない | nil を返却、投稿は保存可能 |
| API制限超過 | nil を返却、ログ出力 |
| ネットワークエラー | nil を返却、ログ出力 |

※YouTube情報の取得失敗が投稿保存をブロックしない設計

## 影響範囲
- Postモデル: コールバック追加、ransackable_attributes拡張
- PostsController: autocompleteの検索対象拡張
- DBスキーマ: 2カラム追加
- 新規ファイル: YoutubeService, 初期化設定, rakeタスク

## セキュリティ考慮
- APIキーは環境変数で管理
- APIキーはサーバーサイドのみで使用（クライアントに露出しない）
- SQLインジェクション対策: パラメータバインディング使用

## テスト計画
- YoutubeService: WebMockでAPIレスポンスをモック
- Postモデル: YouTube情報取得のコールバックテスト
- オートコンプリート: 検索対象拡張の確認

## 参考資料
- https://github.com/googleapis/google-api-ruby-client
- https://developers.google.com/youtube/v3/docs/videos/list
- https://qiita.com/at946/items/b11c9ad65ae1a37ed67f
