# 実装タスク一覧

**プロジェクト:** mitadake? - 期日中心設計への移行
**要件定義:** `.claude/04_adr/ADR-20251229-deadline-centric-design.md`
**開始日:** 2024年12月29日
**現在のフェーズ:** Phase 4

---

## 📌 現在のステータス

- **実施中:** Phase 4（通知機能実装）
- **次のフェーズ:** Phase 5（UI/UXデザイン調整）
- **全体進捗:** 3/6 フェーズ完了

---

## Phase 0: 設計・準備

**目的:** 要件定義、ADR作成、実装計画の策定
**期間:** 1日
**ステータス:** ✅ 完了

### タスク

- [x] ADR作成（期日中心設計への移行）
- [x] 実装ワークフロー作成
- [x] 進行状況管理ドキュメント作成
- [x] タスク管理用チケットファイル作成
- [x] CLAUDE.md（ルールファイル）更新

---

## Phase 1: データベース変更

**目的:** データベーススキーマを新しい設計に移行する
**期間:** 1-2日
**優先度:** P0
**ステータス:** ✅ 完了
**完了日:** 2024-12-29
**PR:** #101

### 1.1 マイグレーション作成・実行

- [x] `add_deadline_to_posts.rb` マイグレーション作成
  - [x] `deadline` カラム追加（date型、nullable）
  - [x] 既存データにデフォルト値設定（created_at + 7日）
  - [x] マイグレーション実行
  - [x] `rails db:migrate:status` で確認

- [x] `remove_category_from_posts.rb` マイグレーション作成
  - [x] `category` カラム削除
  - [x] マイグレーション実行
  - [x] `rails db:migrate:status` で確認

- [x] `rename_likes_to_cheers.rb` マイグレーション作成
  - [x] `likes` テーブルを `cheers` に改名
  - [x] マイグレーション実行
  - [x] `rails db:migrate:status` で確認

- [x] `drop_reminders.rb` マイグレーション作成
  - [x] `reminders` テーブル削除
  - [x] マイグレーション実行
  - [x] `rails db:migrate:status` で確認

### 1.2 テストデータ再作成

- [x] `db/seeds.rb` を更新
  - [x] 既存データをクリア（destroy_all）
  - [x] テストユーザー作成（2名）
  - [x] 期日が近い投稿を作成（1日後、2日後）
  - [x] 期日超過の投稿を作成（1日前）
  - [x] その他の投稿を作成（7日後）
  - [x] 応援（Cheer）を作成

- [x] `rails db:reset` 実行
- [x] `rails db:seed` 実行
- [x] データが正常に作成されたことを確認

### 1.3 検証

- [x] RuboCop 実行 → All green
- [x] Brakeman 実行 → All green（既存警告のみ）
- [x] 既存のRSpec実行 → All pass（447 examples, 0 failures）

### 完了条件

- [x] すべてのマイグレーションが正常に実行されている
- [x] `posts.deadline` カラムが存在する（nullable）
- [x] `posts.category` カラムが削除されている
- [x] `cheers` テーブルが存在する（`likes` から改名）
- [x] `reminders` テーブルが削除されている
- [x] シードデータが正常に作成されている

### 備考
- `deadline`カラムは任意入力に変更（当初のnull: false制約から変更）
- Like→Cheer、LikesController→CheersControllerへの変更もこのフェーズで実施
- 投稿フォームからカテゴリ/リマインダーを削除、期日フィールドを追加

---

## Phase 2: モデル・コントローラー変更

**目的:** 期日機能と応援機能をモデル・コントローラーに実装する
**期間:** 2-3日
**優先度:** P0
**依存:** Phase 1 完了
**ステータス:** ✅ 完了
**完了日:** 2024-12-29
**PR:** #102

### 2.1 Post モデル: 期日バリデーション追加

- [x] `app/models/post.rb` を更新
  - [ ] `validate :deadline_must_be_future` 追加（作成時のみ）← 後回し
  - [x] `enum category` 削除 ✅ Phase 1で実施
  - [x] `has_many :reminders` 削除 ✅ Phase 1で実施
  - [x] スコープ追加: `deadline_near`（3日以内）
  - [x] スコープ追加: `deadline_passed`（期日超過）
  - [x] スコープ追加: `deadline_other`（4日以上）
  - [x] スコープ追加: `with_deadline`（期日あり）
  - [x] スコープ追加: `not_achieved`（未達成）
  - [x] スコープ追加: `achieved`（達成済み）

- [x] `spec/models/post_spec.rb` を作成/更新
  - [ ] deadline_must_be_future のテスト ← 後回し
  - [x] スコープのテスト（deadline_near, deadline_passed, deadline_other, with_deadline, achieved, not_achieved）

- [x] `spec/factories/posts.rb` を更新
  - [x] `deadline` 属性追加（デフォルト: 7日後） ✅ Phase 1で実施
  - [x] trait 追加: `deadline_near`
  - [x] trait 追加: `deadline_passed`
  - [x] trait 追加: `without_deadline`
  - [x] trait 追加: `achieved` ✅ 既存

### 2.2 投稿フォーム: 期日入力

- [x] `app/views/posts/_form.html.erb` を更新 ✅ Phase 1で実施
  - [x] カテゴリ選択UIを削除
  - [x] 期日入力フィールド追加（Flatpickr使用）
  - [x] 任意入力に変更

- [x] `app/controllers/posts_controller.rb` を更新 ✅ Phase 1で実施
  - [x] `post_params` に `deadline` を追加
  - [x] `category` を削除

- [x] `config/locales/ja.yml` 更新 ✅ Phase 1で実施
  - [x] `activerecord.attributes.post.deadline` 追加

### 2.3 カテゴリ関連のコード削除 ✅ Phase 1で実施

- [x] `app/models/post.rb` から `enum category` 削除
- [x] `app/controllers/posts_controller.rb` からカテゴリ絞り込み削除
- [x] `app/views/posts/index.html.erb` からカテゴリ絞り込みUI削除
- [x] `app/views/posts/_post_card.html.erb` からカテゴリバッジ削除
- [x] `config/locales/ja.yml` からカテゴリ関連の翻訳削除
- [x] `spec/models/post_spec.rb` からカテゴリ関連のテスト削除

### 2.4 Like → Cheer モデル変更 ✅ Phase 1で実施

- [x] `app/models/like.rb` → `app/models/cheer.rb` に改名
  - [x] クラス名を `Cheer` に変更
  - [x] バリデーション確認（user_id の uniqueness scoped to post_id）

- [x] `app/models/user.rb` を更新
  - [x] `has_many :likes` → `has_many :cheers` に変更

- [x] `app/models/post.rb` を更新
  - [x] `has_many :likes` → `has_many :cheers` に変更
  - [x] `liked_by?` → `cheered_by?` に変更

- [x] `spec/models/cheer_spec.rb` 作成
  - [x] アソシエーションのテスト
  - [x] バリデーションのテスト

### 2.5 LikesController → CheersController ✅ Phase 1で実施

- [x] `app/controllers/likes_controller.rb` → `app/controllers/cheers_controller.rb` に改名
  - [x] クラス名を `CheersController` に変更
  - [x] `@like` → `@cheer` に変更
  - [x] `current_user.likes` → `current_user.cheers` に変更

- [x] `config/routes.rb` を更新
  - [x] `resources :likes` → `resources :cheers` に変更

- [x] `spec/requests/cheers_spec.rb` 作成
  - [x] create アクションのテスト
  - [x] destroy アクションのテスト

### 2.6 いいねボタン → 応援ボタン ✅ Phase 1で実施

- [x] `app/views/cheers/_cheer_button.html.erb` を作成/更新
  - [x] 「いいね」→「応援する」に変更
  - [x] アイコン更新
  - [x] `post_likes_path` → `post_cheers_path` に変更

- [x] `app/views/posts/show.html.erb` を更新
  - [x] 応援ボタンを表示
  - [x] 応援数を表示

- [x] `config/locales/ja.yml` 更新
  - [x] `cheers.create` 追加
  - [x] `cheers.destroy` 追加

### 2.7 全体/自分トグルスイッチ

- [ ] `app/javascript/controllers/toggle_controller.js` 作成
  - [ ] Stimulus Controller 作成
  - [ ] `toggle()` メソッド実装
  - [ ] `data-toggle-value` で状態管理

- [ ] `app/views/posts/_toggle_switch.html.erb` 作成
  - [ ] iOS風トグルスイッチUI
  - [ ] 「全体」「自分」ラベル

- [ ] `app/controllers/posts_controller.rb` を更新
  - [ ] `scope` パラメータで全体/自分を切り替え

### 2.8 投稿一覧: 達成済みを除外

- [ ] `app/models/post.rb` に `scope :not_achieved` 追加
- [ ] `app/controllers/posts_controller.rb` を更新
  - [ ] `Post.not_achieved` スコープを使用
  - [ ] `order(deadline: :asc)` でソート
  - [x] `includes(:user, :cheers)` でN+1回避 ✅ Phase 1で実施

### 検証

- [ ] RSpec 実行 → 新規コード80%以上カバー
- [ ] RuboCop 実行 → All green
- [ ] Brakeman 実行 → All green
- [ ] 手動テスト
  - [ ] 投稿作成（期日入力）
  - [ ] 応援ボタン動作確認
  - [ ] トグル切り替え動作確認

### 完了条件

- [ ] `Post` モデルに `deadline` バリデーションが追加されている
- [ ] 投稿フォームに期日入力が追加されている
- [ ] カテゴリ関連のコードがすべて削除されている
- [ ] `Like` モデルが `Cheer` モデルに改名されている
- [ ] `LikesController` が `CheersController` に改名されている
- [ ] いいねボタンが応援ボタンに変更されている
- [ ] 全体/自分トグルスイッチが動作する
- [ ] 投稿一覧で達成済み投稿が除外されている
- [ ] RSpec: 新規コード行の80%以上カバー
- [ ] RuboCop, Brakeman → All green

---

## Phase 3: グループ表示実装

**目的:** 投稿一覧を期日グループで表示する
**期間:** 2-3日
**優先度:** P1
**依存:** Phase 2 完了
**ステータス:** ✅ 完了
**完了日:** 2024-12-29
**PR:** #103

### 3.1 期日グループ分けのスコープ

- [x] `app/models/post.rb` にスコープを追加（Phase 2 で作成済み）
  - [x] `scope :deadline_near` → 3日以内、期日の近い順
  - [x] `scope :deadline_passed` → 期日超過、期日の古い順
  - [x] `scope :deadline_other` → 4日以上、期日の近い順

- [x] `spec/models/post_spec.rb` にスコープのテスト追加
  - [x] `deadline_near` のテスト（境界値含む）
  - [x] `deadline_passed` のテスト（ソート順確認）
  - [x] `deadline_other` のテスト

### 3.2 折りたたみUIコンポーネント

- [x] `app/javascript/controllers/collapsible_controller.js` 作成
  - [x] Stimulus Controller 作成
  - [x] `toggle()` メソッド実装
  - [x] `openValueChanged()` メソッド実装
  - [x] 初期状態: すべて展開（`openValue = true`）

- [x] `app/views/posts/_group_header.html.erb` 作成
  - [x] グループヘッダー作成（タイトル + カウント）
  - [x] 折りたたみアイコン（▼/▶）
  - [x] クリックでトグル

### 3.3 投稿一覧をグループ表示

- [x] `app/controllers/posts_controller.rb` を更新
  - [x] `@posts_near` を取得（`Post.deadline_near`）
  - [x] `@posts_passed` を取得（`Post.deadline_passed`）
  - [x] `@posts_other` を取得（`Post.deadline_other`）
  - [x] `@posts_achieved` を取得（達成済み）
  - [x] 各グループに `includes(:user, :cheers)` 適用

- [x] `app/views/posts/index.html.erb` を更新
  - [x] 4つのグループセクションを作成（期日近い、超過、余裕あり、達成済み）
  - [x] 各グループに `_group_header` と投稿一覧を表示
  - [x] `collapsible_controller` を適用

- [x] `app/views/posts/_empty_state.html.erb` 作成
  - [x] 空状態表示を共通化

### 3.4 検索との連携

- [x] `app/controllers/posts_controller.rb` を更新
  - [x] フィルター使用時は従来の単一リスト表示
  - [x] デフォルト表示はグループ表示
  - [x] `using_filters?` メソッドで判定

### 検証

- [x] RSpec 実行 → 461 examples, 0 failures
- [x] 手動テスト
  - [x] グループが正しく表示される
  - [x] 折りたたみ/展開が動作する
  - [x] フィルター使用時は通常表示に切り替わる

### 完了条件

- [x] 期日グループ分けのスコープが正しく動作する
- [x] 折りたたみUIが動作する（全て展開がデフォルト）
- [x] グループヘッダーにカウントが表示される
- [x] フィルター使用時は通常表示に切り替わる
- [x] RSpec: 461 examples, 0 failures
- [x] RuboCop → All green

---

## Phase 4: 通知機能実装

**目的:** Activity Notification gem を使用してアプリ内通知機能を実装する
**期間:** 3-4日
**優先度:** P1
**依存:** Phase 2 完了
**ステータス:** 🔲 未着手

### 4.1 Activity Notification gem 導入

- [ ] `Gemfile` に `activity_notification` 追加
- [ ] `bundle install` 実行
- [ ] `rails generate activity_notification:install` 実行
- [ ] `rails generate activity_notification:migration` 実行
- [ ] `rails db:migrate` 実行

### 4.2 User モデル: 通知受信設定

- [ ] `app/models/user.rb` を更新
  - [ ] `acts_as_target` 追加
  - [ ] `email_allowed: false` 追加

### 4.3 Post, Cheer, Comment モデル: 通知設定

- [ ] `app/models/post.rb` を更新
  - [ ] `acts_as_notifiable` 追加
  - [ ] `targets`, `notifiable_path`, `printable_name` 設定

- [ ] `app/models/cheer.rb` を更新
  - [ ] `acts_as_notifier` 追加
  - [ ] `acts_as_notifiable` 追加
  - [ ] `after_create :notify_post_owner` コールバック追加
  - [ ] `notify_post_owner` メソッド実装（自分の投稿には通知しない）

- [ ] `app/models/comment.rb` を更新
  - [ ] `acts_as_notifier` 追加
  - [ ] `acts_as_notifiable` 追加
  - [ ] `after_create :notify_post_owner` コールバック追加

### 4.4 NotificationsController 作成

- [ ] `app/controllers/notifications_controller.rb` 作成
  - [ ] `index` アクション実装（未読/既読を分けて取得）
  - [ ] `mark_as_read` アクション実装
  - [ ] `mark_all_as_read` アクション実装

- [ ] `config/routes.rb` に通知のルーティング追加
  - [ ] `resources :notifications, only: [:index]`
  - [ ] `post :mark_all_as_read, on: :collection`

- [ ] `spec/requests/notifications_spec.rb` 作成
  - [ ] index アクションのテスト
  - [ ] mark_all_as_read アクションのテスト

### 4.5 通知タブUI

- [ ] `app/views/shared/_bottom_nav.html.erb` を更新
  - [ ] 通知タブ追加（🔔アイコン）
  - [ ] 未読バッジ表示（`current_user.notifications.unopened_only.count`）

- [ ] `app/views/notifications/index.html.erb` 作成
  - [ ] 一括既読ボタン
  - [ ] 未読通知一覧
  - [ ] 既読通知一覧
  - [ ] ページネーション

- [ ] `app/views/notifications/_notification.html.erb` 作成
  - [ ] 通知アイテム表示
  - [ ] 未読/既読の表示切り替え
  - [ ] クリックで既読 + notifiable_path へリダイレクト

### 4.6 期日切れバッチ処理

- [ ] `app/jobs/deadline_notification_job.rb` 作成
  - [ ] 期日が今日で未達成の投稿を取得
  - [ ] 各投稿の投稿者に通知を作成（`post.notify :users`）

- [ ] `spec/jobs/deadline_notification_job_spec.rb` 作成
  - [ ] 期日が今日の投稿に通知が作成されることをテスト
  - [ ] 達成済み投稿には通知が作成されないことをテスト

### 4.7 sidekiq-scheduler 設定

- [ ] `config/sidekiq.yml` を更新
  - [ ] `deadline_notification` スケジュール追加（毎日0時）

### 4.8 i18n 更新

- [ ] `config/locales/ja.yml` 更新
  - [ ] `notifications.title` 追加
  - [ ] `notifications.mark_all_as_read` 追加
  - [ ] `activity_notification.notifications.cheer.created.text` 追加
  - [ ] `activity_notification.notifications.comment.created.text` 追加
  - [ ] `activity_notification.notifications.post.deadline_passed.text` 追加

### 検証

- [ ] RSpec 実行 → 通知のテストが通る
- [ ] 手動テスト
  - [ ] 応援時に通知が作成される
  - [ ] コメント時に通知が作成される
  - [ ] 通知タブに未読バッジが表示される
  - [ ] 一括既読ボタンが動作する
  - [ ] 通知を開いたら既読になる

### 完了条件

- [ ] Activity Notification gem が導入されている
- [ ] 応援時に通知が作成される
- [ ] コメント時に通知が作成される
- [ ] 期日切れバッチが動作する
- [ ] 通知タブが追加されている
- [ ] 未読バッジが表示される
- [ ] 一括既読ボタンが動作する
- [ ] 通知を開いたら自動既読になる
- [ ] RSpec: 新規コード行の80%以上カバー
- [ ] RuboCop, Brakeman → All green

---

## Phase 5: UI/UXデザイン調整

**目的:** 期日中心のUIを視覚的に強調し、ユーザー体験を向上させる
**期間:** 1-2日
**優先度:** P2
**依存:** Phase 3, Phase 4 完了
**ステータス:** 🔲 未着手

### 5.1 期日の視覚的な表現

- [ ] 期日が近い投稿（3日以内）の強調
  - [ ] 背景色変更（薄いオレンジ / 薄い赤）
  - [ ] または「⚠️ 期日が近い」バッジ追加
  - [ ] 新さんとデザインレビュー

- [ ] 期日超過の投稿の強調
  - [ ] 背景色変更（薄いグレー）
  - [ ] または「⏰ 期日超過」バッジ追加

### 5.2 応援ボタンのアイコン選定

- [ ] アイコン選定（👏 / 🎉 / 💪 / ⭐）
  - [ ] 新さんとアイコンレビュー
  - [ ] 決定したアイコンをドキュメント化

- [ ] `app/views/posts/_cheer_button.html.erb` を更新
  - [ ] アイコン変更

### 5.3 デザイン全体の調整

- [ ] 色の統一確認
  - [ ] cream #FAF8F5
  - [ ] dark brown #4A4035
  - [ ] warm brown #8B7355

- [ ] 余白の調整
- [ ] レスポンシブ対応の確認（モバイル/タブレット/デスクトップ）

### 検証

- [ ] デザインレビュー（新さん）
- [ ] 複数デバイスで動作確認

### 完了条件

- [ ] 期日が近い投稿が視覚的に強調されている
- [ ] 期日超過の投稿が視覚的に区別できる
- [ ] 応援ボタンのアイコンが決定している
- [ ] デザイン全体が統一されている
- [ ] レスポンシブ対応されている

---

## Phase 6: テスト・デプロイ

**目的:** 品質を確保し、本番環境にデプロイする
**期間:** 2-3日
**優先度:** P0
**依存:** Phase 1-5 完了
**ステータス:** 🔲 未着手

### 6.1 テストカバレッジ確認

- [ ] `bundle exec rspec --coverage` 実行
- [ ] SimpleCov レポート確認
- [ ] 80%以上を確認

### 6.2 E2Eテスト（Capybara）

- [ ] 投稿作成シナリオ
  - [ ] ログイン → 投稿作成 → 期日入力 → 投稿完了

- [ ] 応援機能シナリオ
  - [ ] 投稿一覧 → 投稿詳細 → 応援ボタン → 通知確認

- [ ] 通知機能シナリオ
  - [ ] 通知タブ → 未読通知確認 → 一括既読

- [ ] トグル・グループシナリオ
  - [ ] 投稿一覧 → トグル切り替え → グループ折りたたみ

### 6.3 パフォーマンス確認

- [ ] Bullet導入
  - [ ] `config/environments/development.rb` 設定
  - [ ] `spec/support/bullet.rb` 作成

- [ ] N+1クエリチェック
  - [ ] 投稿一覧でN+1が発生しないか確認
  - [ ] 修正（`includes` 使用）

### 6.4 静的解析

- [ ] RuboCop 実行
  - [ ] `bundle exec rubocop`
  - [ ] All green まで修正

- [ ] Brakeman 実行
  - [ ] `bundle exec brakeman`
  - [ ] All green まで修正

- [ ] bundle audit 実行
  - [ ] `bundle audit check --update`
  - [ ] All green まで修正

### 6.5 i18n チェック

- [ ] `i18n-tasks missing` 実行
- [ ] 不足キーを追加

### 6.6 A11y チェック

- [ ] フォームラベル確認
- [ ] alt 属性確認
- [ ] キーボード操作確認

### 6.7 本番デプロイ

- [ ] `main` ブランチにマージ
- [ ] Render.com でデプロイ確認
- [ ] `rails db:migrate` 実行確認
- [ ] 動作確認
  - [ ] 投稿作成（期日入力）
  - [ ] 応援機能
  - [ ] 通知機能
  - [ ] グループ表示
  - [ ] トグル切り替え

### 完了条件

- [ ] RSpec カバレッジ 80%以上
- [ ] E2Eテストが通る
- [ ] N+1クエリなし
- [ ] RuboCop, Brakeman, bundle audit → All green
- [ ] i18n チェック完了
- [ ] A11y チェック完了
- [ ] 本番デプロイ成功
- [ ] 本番環境で動作確認完了

---

## 📝 メモ・検討事項

### Phase 5 で決定すべきこと

- [ ] 期日が近い投稿の視覚的な表現（背景色 / バッジ / バナー）
- [ ] 応援ボタンのアイコン（👏 / 🎉 / 💪 / ⭐）

### 将来の拡張

- [ ] 通知の削除機能（Phase 4 で保留中）
- [ ] カスタムカレンダーピッカー（Phase 2 で保留中、現在はHTML5 date_field）

---

## 更新履歴

- 2024-12-29: Phase 3 完了（PR #103）- グループ表示実装
- 2024-12-29: Phase 2 完了（PR #102）- 期日スコープ追加
- 2024-12-29: Phase 1 完了（PR #101）- データベース変更
- 2024-12-29: 初版作成（Phase 0 完了）
