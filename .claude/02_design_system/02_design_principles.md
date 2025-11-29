# デザイン原則

## 概要

ActionSparkのUI/UXデザインにおける基本原則を定義します。

## コアプリンシプル

### 1. シンプル（Simple）

**「3タップ以内で主要操作完了」**

- 不要な要素を排除
- 一画面に一つの目的
- 直感的な操作フロー

```erb
<%# 良い例：シンプルなアクション %>
<div class="flex gap-2">
  <%= button_tag '達成！', class: 'btn btn-primary btn-lg' %>
</div>

<%# 悪い例：情報過多 %>
<div class="flex gap-2">
  <%= button_tag '達成', class: 'btn' %>
  <%= button_tag '後で', class: 'btn' %>
  <%= button_tag 'スキップ', class: 'btn' %>
  <%= button_tag '詳細', class: 'btn' %>
</div>
```

### 2. 直感的（Intuitive）

**「アイコンと色による視覚的フィードバック」**

- アフォーダンスを意識
- 一貫したパターン
- 明確なフィードバック

```erb
<%# 達成状態を色で表現 %>
<% if achieved_today? %>
  <button class="bg-emerald-500 text-white" disabled>
    ✓ 達成済み
  </button>
<% else %>
  <button class="bg-yellow-400 hover:bg-yellow-500">
    達成！
  </button>
<% end %>
```

### 3. モチベーション重視（Motivating）

**「達成感を演出する要素」**

- ポジティブなフィードバック
- 進捗の可視化
- 小さな成功の積み重ね

```erb
<%# バッジによる達成感 %>
<span class="text-2xl"><%= achievement_badge %></span>
<span class="text-sm text-gray-500"><%= achievement_count %>回達成</span>

<%# 達成時のアニメーション %>
<div class="animate-bounce" data-controller="celebration">
  🎉
</div>
```

### 4. モバイルファースト（Mobile First）

**「スマートフォンでの使いやすさ優先」**

- タップ領域は44px以上
- 片手操作を考慮
- レスポンシブデザイン

```erb
<%# タッチフレンドリーなボタン %>
<button class="min-h-[44px] min-w-[44px] px-4 py-3">
  タップ
</button>

<%# モバイルでのフルワイドボタン %>
<button class="w-full md:w-auto">
  投稿する
</button>
```

## アクセシビリティ

### 基本方針

- WCAG 2.1 レベルAA準拠
- キーボード操作対応
- スクリーンリーダー対応
- 色だけに頼らない情報伝達

### 実装ガイドライン

#### コントラスト比

- 本文テキスト: 4.5:1以上
- 大きなテキスト: 3:1以上
- UI要素: 3:1以上

```erb
<%# 良い例：十分なコントラスト %>
<p class="text-gray-700 bg-white">本文テキスト</p>

<%# 悪い例：コントラスト不足 %>
<p class="text-gray-400 bg-gray-100">読みにくいテキスト</p>
```

#### フォーカス表示

```erb
<button class="focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-black">
  ボタン
</button>

<input class="focus:border-black focus:ring-1 focus:ring-black">
```

#### ARIAラベル

```erb
<%# アイコンのみのボタン %>
<button aria-label="いいね">
  <svg>...</svg>
</button>

<%# 状態の通知 %>
<div role="status" aria-live="polite">
  <%= flash[:notice] %>
</div>
```

#### スキップリンク

```erb
<a href="#main-content" class="sr-only focus:not-sr-only">
  メインコンテンツへスキップ
</a>
```

## コンテンツ原則

### 文言ガイドライン

#### トーン

- 親しみやすく、励ましになる
- 押し付けがましくない
- 簡潔で明確

```erb
<%# 良い例 %>
<p>今日も一歩前進しましたね！</p>

<%# 悪い例 %>
<p>達成処理が完了しました。</p>
```

#### ラベル

| 種類 | 良い例 | 悪い例 |
|------|--------|--------|
| ボタン | 投稿する | Submit |
| フォーム | きっかけ | trigger_content |
| エラー | 100文字以内で入力してください | Error: max length exceeded |

### 空状態

```erb
<%# 投稿がない場合 %>
<div class="text-center py-12">
  <div class="text-4xl mb-4">✨</div>
  <h3 class="text-lg font-medium text-gray-900">まだ投稿がありません</h3>
  <p class="text-gray-500 mt-2">最初の一歩を記録してみましょう</p>
  <%= link_to '投稿する', new_post_path, class: 'btn btn-primary mt-4' %>
</div>
```

### ローディング状態

```erb
<%# スケルトンUI %>
<div class="animate-pulse">
  <div class="h-4 bg-gray-200 rounded w-3/4 mb-2"></div>
  <div class="h-4 bg-gray-200 rounded w-1/2"></div>
</div>

<%# スピナー %>
<div class="flex items-center justify-center">
  <svg class="animate-spin h-5 w-5 text-gray-500" viewBox="0 0 24 24">
    ...
  </svg>
  <span class="ml-2">読み込み中...</span>
</div>
```

## インタラクション

### ホバー状態

```erb
<%# カード %>
<div class="bg-white hover:bg-gray-50 transition-colors cursor-pointer">

<%# リンク %>
<a class="text-black hover:text-gray-600 underline hover:no-underline">

<%# ボタン %>
<button class="bg-black hover:bg-gray-800 active:bg-gray-900">
```

### クリック/タップフィードバック

```erb
<%# ボタンの押下状態 %>
<button class="transform active:scale-95 transition-transform">

<%# いいねボタン %>
<button class="hover:text-red-500 active:scale-110 transition-all"
        data-controller="like"
        data-action="click->like#toggle">
  ❤️
</button>
```

### アニメーション

```javascript
// app/javascript/controllers/celebration_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.element.classList.add('animate-bounce')
    setTimeout(() => {
      this.element.classList.remove('animate-bounce')
    }, 1000)
  }
}
```

## レイアウトパターン

### カードグリッド

```erb
<div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
  <% @posts.each do |post| %>
    <%= render 'posts/card', post: post %>
  <% end %>
</div>
```

### センタリング

```erb
<%# 水平中央 %>
<div class="max-w-2xl mx-auto">

<%# 完全中央 %>
<div class="flex items-center justify-center min-h-screen">
```

### フォームレイアウト

```erb
<div class="space-y-6">
  <div>
    <%= f.label :trigger_content, class: 'block text-sm font-medium text-gray-700' %>
    <%= f.text_area :trigger_content, class: 'mt-1 block w-full rounded-md border-gray-300' %>
  </div>

  <div>
    <%= f.label :action_plan, class: 'block text-sm font-medium text-gray-700' %>
    <%= f.text_area :action_plan, class: 'mt-1 block w-full rounded-md border-gray-300' %>
  </div>
</div>
```

## チェックリスト

### 実装時の確認項目

- [ ] モバイルで操作しやすいか（タップ領域44px以上）
- [ ] 色だけでなくテキストやアイコンで情報を伝えているか
- [ ] フォーカス状態が視認できるか
- [ ] コントラスト比が十分か
- [ ] 空状態が用意されているか
- [ ] ローディング状態があるか
- [ ] エラーメッセージが分かりやすいか

---

*関連ドキュメント*: `01_design_tokens.md`, `03_components.md`
