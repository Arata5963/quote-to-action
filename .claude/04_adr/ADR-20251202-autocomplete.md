# ADR-20251202: オートコンプリート検索機能

## ステータス
承認済み

## コンテキスト
投稿一覧ページの検索機能を強化し、ユーザーがキーワードを入力中に候補を表示するオートコンプリート機能を実装する。

### 現状
- Ransackによるキーワード検索が実装済み
- 検索対象: `trigger_content`, `action_plan`
- importmap-railsでJSを管理

### 要件
- 検索ボックスに入力中、候補をリアルタイム表示
- 候補選択時は検索ボックスに入力し、検索ボタンで実行
- Phase 1: テキスト（trigger_content, action_plan）のみ
- Phase 2（将来）: YouTube API連携でタイトル・チャンネル名も検索可能に

## 決定
**stimulus-autocomplete** を採用する。

### 選択理由
| 観点 | 評価 |
|------|------|
| 導入の手軽さ | ◎ importmap pin 1行 |
| 技術スタックとの整合性 | ◎ Stimulus標準 |
| 日本語ドキュメント | ◎ Qiita/Zenn記事多数 |
| カスタマイズ性 | △ 限定的（今回は十分） |
| 軽量性 | ◎ 1.5kB gzipped |

### 不採用案
- **自作Stimulus Controller**: 学習効果は高いが工数過多
- **Turbo Framesのみ**: リクエスト過多になりやすい
- **hotwire_combobox**: まだベータ版

## 実装計画

### ファイル構成
```
app/
├── controllers/
│   └── posts_controller.rb      # autocompleteアクション追加
├── javascript/
│   └── controllers/
│       └── application.js       # Autocomplete登録
└── views/
    └── posts/
        └── autocomplete.html.erb # 候補リストのパーシャル

config/
├── importmap.rb                 # stimulus-autocomplete pin追加
└── routes.rb                    # autocompleteルート追加
```

### 実装ステップ
1. stimulus-autocompleteのインストール
2. application.jsにAutocomplete登録
3. PostsController#autocomplete実装
4. ルーティング追加
5. autocomplete.html.erb作成
6. 検索フォームにdata-controller追加
7. スタイリング調整
8. テスト作成

### API仕様
```
GET /posts/autocomplete?q=Ruby
```

レスポンス（HTML）:
```html
<li role="option" data-autocomplete-value="Ruby on Rails">
  Ruby on Rails入門 - きっかけ
</li>
<li role="option" data-autocomplete-value="Rubyで自動化">
  Rubyで自動化 - アクションプラン
</li>
```

### 検索ロジック
```ruby
# trigger_content OR action_plan に部分一致
Post.where("trigger_content ILIKE :q OR action_plan ILIKE :q", q: "%#{query}%")
    .limit(10)
    .pluck(:trigger_content, :action_plan)
    .flatten
    .uniq
```

## 影響範囲
- PostsController: autocompleteアクション追加
- routes.rb: collection route追加
- 検索フォームビュー: data属性追加
- CSS: 候補リストのスタイル

## セキュリティ考慮
- SQLインジェクション対策: パラメータバインディング使用
- XSS対策: ERBのデフォルトエスケープを利用
- レート制限: 将来的にはdebounce（入力後300ms待機）を検討

## テスト計画
- Request spec: autocompleteアクションの動作確認
- System spec: 候補表示・選択の統合テスト（JS必要）

## 参考資料
- https://github.com/afcapel/stimulus-autocomplete
- https://qiita.com/Yamamoto-Masaya1122/items/879d6eb540ce4e05cfe5
- https://zenn.dev/financier_k0hei/scraps/3c3627bcbdf2d5