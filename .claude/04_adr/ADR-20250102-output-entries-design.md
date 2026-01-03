# ADR-001: mitadake? アウトプット機能の基本設計

## ステータス
採用

## 日付
2025-01-02

## コンテキスト

mitadake?は「YouTube動画を見ただけで終わらせない」ためのアプリ。
動画視聴後のアウトプットを促し、ダラダラ見を可視化する。

当初は複数のアウトプット方法（メモ/感想/学び/行動/クイズ等）や、
視聴目的・満足度の記録も検討したが、ActionSparkの教訓
（「何でもアリ」= 価値提案が曖昧）を踏まえ、シンプルさを重視した設計を目指す。

---

## 決定事項

### 1. データ構造：1動画1投稿 + 複数エントリー

**採用:**
```
1動画 = 1投稿（Post）
複数のアウトプット = 複数エントリー（PostEntry）

posts: user_id + youtube_video_id (unique)
post_entries: post_id + entry_type + content + created_at
```

**却下案:**
- 同じ動画×同じタイプで1投稿（3つ投稿ができる）
- 同じ動画でも常に新規投稿

**理由:**
- 「この動画で何をしたか」が一目瞭然
- 学習の履歴が時系列で残る
- 同じ動画を何度見たか可視化できる
- mitadakeのコンセプト「見ただけ？」に合致

---

### 2. アウトプット方法：3種類に絞る

**採用:**
```
📝 メモ
  - テキスト入力（必須）
  - 期日なし

🎯 行動
  - アクションプラン（必須）
  - 期日（必須）
  - 達成機能あり

🗑️ 特になし
  - 入力なし
  - タイムスタンプのみ記録
```

**却下案:**
- 5種類以上（メモ/感想/学び/行動/クイズ）
- メモと行動の2種類のみ

**理由:**
- ActionSparkの教訓：選択肢が多い = 迷う
- 「特になし」でダラダラ見を可視化（コンセプトの核心）
- シンプルで使いやすい
- 後から追加可能

---

### 3. 投稿フロー：シームレスな追記

**採用:**
```
新規投稿も追記も同じフロー
- URL入力 → アウトプット選択 → 投稿
- 裏側で自動的に既存投稿に紐付く
- 警告やモーダルなし
```

**却下案:**
- 「既に投稿があります」と警告を出す
- 追記専用フォームを別途用意

**理由:**
- 投稿のハードルが低い
- ユーザーは「追記」を意識しない
- シームレスな体験

---

### 4. 追記UI：インライン展開

**採用:**
```
詳細ページに「追記する」ボタン
↓
その場でフォームが展開
↓
アウトプット選択 → 追記
```

**却下案:**
- モーダル
- 別ページ遷移

**理由:**
- コンテキストが保たれる（既存エントリーを見ながら入力）
- スクロール位置が変わらない
- スマホでも使いやすい

---

### 5. 動画選択方法

**Phase 1で実装:**
```
1. URL手動入力
2. クリップボード自動検出
```

**Phase 2に保留:**
```
3. タイトル検索
```

**理由:**
- クリップボード検出でURL入力が十分楽になる
- MVP原則：最小限の機能で価値検証
- タイトル検索はAPI quota消費、実装時間増
- 早期リリースを優先

---

### 6. 保留機能

**Phase 2以降:**
```
- 満足度機能
- 視聴目的の記録
- タイトル検索
- 統計・分析
- クイズ機能（AI生成）
```

**理由:**
- コア機能（アウトプット・追記）を先に完成
- ユーザーフィードバックを見てから判断
- シンプルさを保つ

---

## 技術的詳細

### データベース設計
```ruby
# posts テーブル
create_table :posts do |t|
  t.bigint :user_id, null: false
  t.string :youtube_video_id, null: false
  t.string :original_youtube_url
  t.timestamps
  
  t.index [:user_id, :youtube_video_id], unique: true
end

# post_entries テーブル
create_table :post_entries do |t|
  t.bigint :post_id, null: false
  t.integer :entry_type, null: false  # memo/action/nothing
  t.text :content
  t.date :deadline
  t.datetime :achieved_at
  t.timestamps
  
  t.index [:post_id]
end
```

### 既存データ移行
```ruby
# 既存の投稿を変換
- action_plan → Post + PostEntry（entry_type: action）
- category カラムは削除（YouTubeカテゴリは使わない）
```

---

## 結果

### メリット

1. **シンプル**
   - 選択肢が少ない（迷わない）
   - 投稿フローが統一

2. **コンセプトに忠実**
   - 「特になし」でダラダラ見を可視化
   - 行動への変換を促す

3. **拡張性**
   - 後からアウトプット方法追加可能
   - Phase 2で機能拡張可能

4. **ユーザー体験**
   - 投稿ハードルが低い
   - 追記がシームレス

### トレードオフ

1. **実装の複雑さ**
   - テーブルが2つ（Post + PostEntry）
   - 既存データの移行が必要

2. **機能の制限**
   - Phase 1ではタイトル検索なし
   - 満足度機能なし

3. **API依存**
   - クリップボード検出はブラウザ依存
   - フォールバックが必要

---

## 関連ファイル

- `app/models/post.rb`
- `app/models/post_entry.rb`
- `app/controllers/posts_controller.rb`
- `app/controllers/post_entries_controller.rb`
- `app/views/posts/show.html.erb`

---

## 参照

- ActionSparkの失敗事例（選択肢が多すぎる問題）
- mitadake?のコンセプト：「見ただけで終わらせない」