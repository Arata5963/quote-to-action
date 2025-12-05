# ActionSpark UIコンポーネント設計

本ドキュメントでは、ActionSparkで使用するUIコンポーネントのデザインパターンを定義します。

---

## ボタン

### プライマリボタン

メインアクション用。黒背景に白文字。

```html
<button class="bg-gray-900 text-white font-semibold px-6 py-3 rounded-xl shadow-sm hover:bg-gray-800 hover:shadow-md active:bg-gray-700 transition-all">
  投稿する
</button>
```

**バリエーション**:

```html
<!-- 大サイズ -->
<button class="bg-gray-900 text-white font-bold px-8 py-4 rounded-xl text-lg shadow-sm hover:bg-gray-800 hover:shadow-md transition-all">
  投稿する
</button>

<!-- 小サイズ -->
<button class="bg-gray-900 text-white font-medium px-4 py-2 rounded-lg text-sm shadow-sm hover:bg-gray-800 transition-all">
  保存
</button>

<!-- 無効状態 -->
<button class="bg-gray-300 text-gray-500 font-semibold px-6 py-3 rounded-xl cursor-not-allowed" disabled>
  投稿する
</button>
```

### セカンダリボタン

サブアクション用。白背景にグレーボーダー。

```html
<button class="bg-white text-gray-700 font-semibold px-6 py-3 rounded-xl border border-gray-300 shadow-sm hover:bg-gray-50 hover:shadow-md active:bg-gray-100 transition-all">
  キャンセル
</button>
```

### テキストボタン

軽いアクション用。背景なし。

```html
<button class="text-gray-600 font-medium px-4 py-2 rounded-lg hover:bg-gray-100 hover:text-gray-900 transition-all">
  詳細を見る
</button>
```

### アイコンボタン

アイコンのみのボタン。

```html
<button class="p-2 text-gray-500 hover:text-gray-900 hover:bg-gray-100 rounded-lg transition-all">
  <svg class="w-5 h-5" viewBox="0 0 24 24" fill="currentColor">
    <!-- アイコン -->
  </svg>
</button>
```

### デンジャーボタン

削除などの危険なアクション用。

```html
<button class="bg-red-600 text-white font-semibold px-6 py-3 rounded-xl shadow-sm hover:bg-red-700 hover:shadow-md transition-all">
  削除する
</button>

<!-- ゴーストバージョン -->
<button class="text-red-600 font-semibold px-6 py-3 rounded-xl hover:bg-red-50 transition-all">
  削除
</button>
```

---

## カード

### 投稿カード

YouTube動画のサムネイルを大きく表示。

```html
<article class="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden hover:shadow-md transition-shadow">
  <!-- サムネイル -->
  <div class="aspect-video">
    <img
      src="thumbnail.jpg"
      alt="動画タイトル"
      class="w-full h-full object-cover"
    />
  </div>

  <!-- コンテンツ -->
  <div class="p-5">
    <!-- カテゴリバッジ -->
    <div class="mb-3">
      <span class="text-xs bg-gray-100 text-gray-600 px-3 py-1 rounded-full">
        カテゴリ
      </span>
    </div>

    <!-- タイトル -->
    <h3 class="text-lg font-semibold text-gray-900 mb-2 line-clamp-2">
      アクションプランのタイトル
    </h3>

    <!-- 統計情報 -->
    <div class="flex items-center gap-4 text-sm text-gray-500">
      <span class="flex items-center gap-1">
        <svg class="w-4 h-4"><!-- ハートアイコン --></svg>
        12
      </span>
      <span class="flex items-center gap-1">
        <svg class="w-4 h-4"><!-- コメントアイコン --></svg>
        3
      </span>
    </div>

    <!-- CTAボタン -->
    <div class="mt-4">
      <a href="#" class="block w-full text-center bg-gray-900 text-white font-semibold px-4 py-2.5 rounded-xl hover:bg-gray-800 transition-all">
        詳細を見る
      </a>
    </div>
  </div>
</article>
```

### シンプルカード

汎用的なカードコンポーネント。

```html
<div class="bg-white rounded-2xl shadow-sm border border-gray-100 p-6">
  <h3 class="text-lg font-semibold text-gray-900 mb-2">タイトル</h3>
  <p class="text-gray-600">説明テキスト</p>
</div>
```

### フィルターカード

検索・フィルター用のカード。

```html
<div class="bg-white rounded-2xl shadow-sm border border-gray-100 p-6 mb-6">
  <!-- 検索フォーム -->
  <div class="space-y-4">
    <!-- 検索入力 -->
    <div>
      <label class="block text-sm font-medium text-gray-700 mb-1">キーワード</label>
      <input type="text" class="w-full px-4 py-3 rounded-xl border border-gray-300 focus:border-gray-500 focus:ring-2 focus:ring-gray-200 transition-all" placeholder="検索..." />
    </div>

    <!-- フィルター -->
    <div class="flex gap-2 flex-wrap">
      <button class="px-4 py-2 rounded-full bg-gray-900 text-white text-sm font-medium">すべて</button>
      <button class="px-4 py-2 rounded-full bg-gray-100 text-gray-700 text-sm font-medium hover:bg-gray-200 transition-colors">達成済み</button>
      <button class="px-4 py-2 rounded-full bg-gray-100 text-gray-700 text-sm font-medium hover:bg-gray-200 transition-colors">未達成</button>
    </div>
  </div>
</div>
```

---

## フォーム

### テキスト入力

```html
<div>
  <label class="block text-sm font-medium text-gray-700 mb-2">
    ラベル <span class="text-red-500">*</span>
  </label>
  <input
    type="text"
    class="w-full px-4 py-3 rounded-xl border border-gray-300 text-gray-900 placeholder-gray-400 focus:border-gray-500 focus:ring-2 focus:ring-gray-200 transition-all"
    placeholder="入力してください"
  />
  <p class="mt-1 text-sm text-gray-500">ヘルプテキスト</p>
</div>
```

### テキストエリア

```html
<div>
  <label class="block text-sm font-medium text-gray-700 mb-2">
    アクションプラン
  </label>
  <textarea
    rows="4"
    class="w-full px-4 py-3 rounded-xl border border-gray-300 text-gray-900 placeholder-gray-400 focus:border-gray-500 focus:ring-2 focus:ring-gray-200 transition-all resize-none"
    placeholder="どんなアクションを起こしますか？"
  ></textarea>
</div>
```

### セレクトボックス

```html
<div>
  <label class="block text-sm font-medium text-gray-700 mb-2">
    カテゴリ
  </label>
  <select class="w-full px-4 py-3 rounded-xl border border-gray-300 text-gray-900 focus:border-gray-500 focus:ring-2 focus:ring-gray-200 transition-all">
    <option value="">選択してください</option>
    <option value="1">カテゴリ1</option>
    <option value="2">カテゴリ2</option>
  </select>
</div>
```

### URL入力（YouTube用）

```html
<div>
  <label class="block text-sm font-medium text-gray-700 mb-2">
    YouTube URL <span class="text-red-500">*</span>
  </label>
  <input
    type="url"
    class="w-full px-4 py-3 rounded-xl border border-gray-300 text-gray-900 placeholder-gray-400 focus:border-gray-500 focus:ring-2 focus:ring-gray-200 transition-all"
    placeholder="https://www.youtube.com/watch?v=..."
  />
  <p class="mt-1 text-sm text-gray-500">YouTube動画のURLを入力してください</p>
</div>
```

### エラー状態

```html
<div>
  <label class="block text-sm font-medium text-gray-700 mb-2">
    入力フィールド
  </label>
  <input
    type="text"
    class="w-full px-4 py-3 rounded-xl border-2 border-red-500 text-gray-900 focus:ring-2 focus:ring-red-200 transition-all"
  />
  <p class="mt-1 text-sm text-red-600">エラーメッセージ</p>
</div>
```

---

## タグ・バッジ

### カテゴリタグ

```html
<span class="text-xs bg-gray-100 text-gray-600 px-3 py-1 rounded-full">
  カテゴリ名
</span>
```

### ステータスバッジ

```html
<!-- 達成済み -->
<span class="inline-flex items-center gap-1 text-xs bg-green-100 text-green-800 px-3 py-1 rounded-full font-medium">
  <svg class="w-3 h-3"><!-- チェックアイコン --></svg>
  達成済み
</span>

<!-- 未達成 -->
<span class="inline-flex items-center gap-1 text-xs bg-gray-100 text-gray-600 px-3 py-1 rounded-full font-medium">
  未達成
</span>
```

### カウントバッジ

```html
<span class="inline-flex items-center justify-center min-w-[20px] h-5 bg-gray-900 text-white text-xs font-bold rounded-full px-1.5">
  3
</span>
```

---

## ユーザー表示

### アバター + 名前

```html
<div class="flex items-center gap-3">
  <img
    src="avatar.jpg"
    alt="ユーザー名"
    class="w-10 h-10 rounded-full object-cover"
  />
  <div>
    <p class="text-sm font-medium text-gray-900">ユーザー名</p>
    <p class="text-xs text-gray-500">2日前</p>
  </div>
</div>
```

### 小アバター

```html
<div class="flex items-center gap-2">
  <img src="avatar.jpg" class="w-8 h-8 rounded-full" />
  <span class="text-sm font-medium text-gray-900">ユーザー名</span>
</div>
```

### アバタープレースホルダー

```html
<div class="w-10 h-10 bg-gray-200 rounded-full flex items-center justify-center">
  <svg class="w-5 h-5 text-gray-400">
    <!-- ユーザーアイコン -->
  </svg>
</div>
```

---

## アラート・メッセージ

### 成功メッセージ

```html
<div class="bg-green-50 border border-green-200 rounded-xl p-4 flex items-start gap-3">
  <svg class="w-5 h-5 text-green-600 flex-shrink-0 mt-0.5"><!-- チェックアイコン --></svg>
  <div>
    <p class="text-sm font-medium text-green-800">投稿が完了しました</p>
  </div>
</div>
```

### エラーメッセージ

```html
<div class="bg-red-50 border border-red-200 rounded-xl p-4 flex items-start gap-3">
  <svg class="w-5 h-5 text-red-600 flex-shrink-0 mt-0.5"><!-- エラーアイコン --></svg>
  <div>
    <p class="text-sm font-medium text-red-800">エラーが発生しました</p>
    <p class="text-sm text-red-700 mt-1">詳細なエラーメッセージ</p>
  </div>
</div>
```

### 情報メッセージ

```html
<div class="bg-blue-50 border border-blue-200 rounded-xl p-4 flex items-start gap-3">
  <svg class="w-5 h-5 text-blue-600 flex-shrink-0 mt-0.5"><!-- 情報アイコン --></svg>
  <div>
    <p class="text-sm font-medium text-blue-800">お知らせ</p>
  </div>
</div>
```

---

## いいね・コメント

### いいねボタン

```html
<!-- 未いいね状態 -->
<button class="flex items-center gap-1.5 text-gray-500 hover:text-red-500 transition-colors">
  <svg class="w-5 h-5" fill="none" stroke="currentColor" stroke-width="2">
    <!-- ハートアイコン（アウトライン） -->
  </svg>
  <span class="text-sm font-medium">12</span>
</button>

<!-- いいね済み状態 -->
<button class="flex items-center gap-1.5 text-red-500 hover:text-red-600 transition-colors">
  <svg class="w-5 h-5" fill="currentColor">
    <!-- ハートアイコン（塗り） -->
  </svg>
  <span class="text-sm font-medium">13</span>
</button>
```

### コメント表示

```html
<div class="bg-gray-50 rounded-xl p-4">
  <!-- ユーザー情報 -->
  <div class="flex items-center gap-2 mb-2">
    <img src="avatar.jpg" class="w-8 h-8 rounded-full" />
    <span class="text-sm font-medium text-gray-900">ユーザー名</span>
    <span class="text-xs text-gray-500">2時間前</span>
  </div>

  <!-- コメント本文 -->
  <p class="text-gray-700 text-sm">
    コメントの内容がここに入ります。
  </p>
</div>
```

---

## 達成ボタン

### 未達成状態

```html
<button class="flex items-center gap-2 bg-gray-900 text-white font-semibold px-6 py-3 rounded-xl shadow-sm hover:bg-gray-800 hover:shadow-md transition-all">
  <svg class="w-5 h-5"><!-- チェックアイコン --></svg>
  達成！
</button>
```

### 達成済み状態

```html
<div class="flex items-center gap-2 bg-green-100 text-green-800 font-bold px-6 py-3 rounded-xl">
  <svg class="w-5 h-5"><!-- チェックアイコン --></svg>
  達成済み
</div>
```

---

## ナビゲーション

### ヘッダー

```html
<header class="bg-white border-b border-gray-200 sticky top-0 z-50">
  <div class="max-w-4xl mx-auto px-4">
    <div class="flex items-center justify-between h-16">
      <!-- ロゴ -->
      <a href="/" class="text-xl font-bold text-gray-900">
        ActionSpark
      </a>

      <!-- ナビゲーション -->
      <nav class="flex items-center gap-4">
        <a href="#" class="text-gray-600 hover:text-gray-900 transition-colors">一覧</a>
        <button class="bg-gray-900 text-white font-medium px-4 py-2 rounded-xl hover:bg-gray-800 transition-all">
          投稿
        </button>
      </nav>
    </div>
  </div>
</header>
```

### パンくずリスト

```html
<nav class="flex items-center gap-2 text-sm text-gray-500 mb-6">
  <a href="/" class="hover:text-gray-900 transition-colors">ホーム</a>
  <span>/</span>
  <a href="/posts" class="hover:text-gray-900 transition-colors">投稿一覧</a>
  <span>/</span>
  <span class="text-gray-900">投稿詳細</span>
</nav>
```

---

## 空状態

```html
<div class="text-center py-12">
  <div class="w-16 h-16 bg-gray-100 rounded-full flex items-center justify-center mx-auto mb-4">
    <svg class="w-8 h-8 text-gray-400"><!-- アイコン --></svg>
  </div>
  <h3 class="text-lg font-semibold text-gray-900 mb-2">投稿がありません</h3>
  <p class="text-gray-500 mb-6">最初の投稿を作成しましょう</p>
  <button class="bg-gray-900 text-white font-semibold px-6 py-3 rounded-xl hover:bg-gray-800 transition-all">
    投稿する
  </button>
</div>
```

---

## ローディング

### スピナー

```html
<div class="animate-spin w-6 h-6 border-2 border-gray-300 border-t-gray-900 rounded-full"></div>
```

### スケルトン

```html
<div class="animate-pulse">
  <div class="aspect-video bg-gray-200 rounded-xl mb-4"></div>
  <div class="h-4 bg-gray-200 rounded w-3/4 mb-2"></div>
  <div class="h-4 bg-gray-200 rounded w-1/2"></div>
</div>
```

---

## 実装時の注意事項

### Railsフォームヘルパーとボタンスタイル

**問題**: Railsの`f.submit`や`button_to`ヘルパーでTailwindクラスを指定しても、スタイルが正しく適用されないことがある。

**原因**:
- `f.submit`は`<input type="submit">`を生成し、一部のTailwindクラスが効かない
- `button_to`はフォームを生成し、クラスの適用が期待通りにならないケースがある
- ブラウザのデフォルトスタイルやCSSリセットが影響する場合がある

**解決策**: 明示的な`<button>`タグを使用し、必要に応じてインラインスタイルを併用する。

```erb
<%# NG: f.submit を使用 %>
<%= f.submit "送信", class: "bg-pink-400 text-white px-5 py-2.5 rounded-full" %>

<%# OK: 明示的な <button> タグを使用 %>
<button type="submit" class="bg-pink-400 text-white px-5 py-2.5 rounded-full">
  送信
</button>

<%# 確実: インラインスタイルを併用 %>
<button type="submit"
        class="rounded-full text-sm font-medium"
        style="background-color: #f472b6; color: white; padding: 10px 20px;">
  送信
</button>
```

### button_to の代替

```erb
<%# NG: button_to with block %>
<%= button_to some_path, method: :post, class: "bg-gray-900 text-white" do %>
  実行
<% end %>

<%# OK: form_with + button %>
<%= form_with url: some_path, method: :post, local: true, class: "inline" do %>
  <button type="submit"
          class="inline-flex items-center gap-2 rounded-xl"
          style="background-color: #111827; color: white; padding: 10px 24px;">
    実行
  </button>
<% end %>
```

### 推奨カラーコード

インラインスタイルで使用する場合の対応表:

| Tailwindクラス | カラーコード |
|---------------|-------------|
| `bg-gray-900` | `#111827` |
| `bg-gray-800` | `#1f2937` |
| `bg-pink-400` | `#f472b6` |
| `bg-pink-500` | `#ec4899` |
| `bg-red-500` | `#ef4444` |
| `bg-red-600` | `#dc2626` |
| `text-white` | `#ffffff` |

---

*最終更新: 2025-12-05*
