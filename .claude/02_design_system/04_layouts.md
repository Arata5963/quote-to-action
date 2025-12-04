# ActionSpark レイアウトシステム

本ドキュメントでは、ActionSparkで使用するレイアウトパターン、グリッドシステム、レスポンシブ対応を定義します。

---

## 基本構造

### ページレイアウト

```html
<div class="min-h-screen bg-gray-50 flex flex-col">
  <!-- ヘッダー -->
  <header class="bg-white border-b border-gray-200 sticky top-0 z-50">
    ...
  </header>

  <!-- メインコンテンツ -->
  <main class="flex-1">
    <div class="max-w-4xl mx-auto px-4 py-8">
      ...
    </div>
  </main>

  <!-- フッター -->
  <footer class="bg-white border-t border-gray-200">
    ...
  </footer>
</div>
```

### コンテナ幅

| 用途 | Tailwind | 最大幅 |
|------|----------|--------|
| 狭い（フォーム等） | `max-w-2xl` | 672px |
| 標準（詳細ページ） | `max-w-4xl` | 896px |
| 広い（一覧ページ） | `max-w-6xl` | 1152px |
| 最大 | `max-w-7xl` | 1280px |

```html
<!-- 狭いコンテナ（フォーム用） -->
<div class="max-w-2xl mx-auto px-4">

<!-- 標準コンテナ -->
<div class="max-w-4xl mx-auto px-4">

<!-- 広いコンテナ（一覧用） -->
<div class="max-w-6xl mx-auto px-4">
```

---

## ヘッダー

### 標準ヘッダー

```html
<header class="bg-white border-b border-gray-200 sticky top-0 z-50">
  <div class="max-w-6xl mx-auto px-4">
    <div class="flex items-center justify-between h-16">

      <!-- ロゴ -->
      <a href="/" class="flex items-center gap-2">
        <div class="w-8 h-8 bg-gray-900 rounded-lg flex items-center justify-center">
          <svg class="w-5 h-5 text-white"><!-- ロゴアイコン --></svg>
        </div>
        <span class="text-xl font-bold text-gray-900">ActionSpark</span>
      </a>

      <!-- ナビゲーション -->
      <nav class="flex items-center gap-4">
        <!-- デスクトップメニュー -->
        <div class="hidden sm:flex items-center gap-4">
          <a href="/posts" class="text-gray-600 hover:text-gray-900 transition-colors">
            一覧
          </a>
        </div>

        <!-- 投稿ボタン -->
        <a href="/posts/new" class="bg-gray-900 text-white font-medium px-4 py-2 rounded-xl hover:bg-gray-800 transition-all">
          投稿
        </a>

        <!-- ハンバーガーメニュー（モバイル） -->
        <button class="sm:hidden p-2 text-gray-600 hover:bg-gray-100 rounded-lg">
          <svg class="w-6 h-6"><!-- メニューアイコン --></svg>
        </button>
      </nav>
    </div>
  </div>
</header>
```

---

## フッター

```html
<footer class="bg-white border-t border-gray-200 mt-auto">
  <div class="max-w-6xl mx-auto px-4 py-8">
    <div class="flex flex-col sm:flex-row items-center justify-between gap-4">

      <!-- ロゴ -->
      <div class="flex items-center gap-2">
        <span class="font-semibold text-gray-900">ActionSpark</span>
      </div>

      <!-- リンク -->
      <nav class="flex items-center gap-6 text-sm">
        <a href="/terms" class="text-gray-500 hover:text-gray-900 transition-colors">
          利用規約
        </a>
        <a href="/privacy" class="text-gray-500 hover:text-gray-900 transition-colors">
          プライバシー
        </a>
        <a href="/contact" class="text-gray-500 hover:text-gray-900 transition-colors">
          お問い合わせ
        </a>
      </nav>
    </div>

    <div class="mt-6 pt-6 border-t border-gray-100 text-center">
      <p class="text-sm text-gray-400">&copy; 2025 ActionSpark</p>
    </div>
  </div>
</footer>
```

---

## グリッドシステム

### カードグリッド（投稿一覧）

```html
<!-- 1列 → 2列 → 3列 -->
<div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
  <!-- カード -->
  <article class="bg-white rounded-2xl shadow-sm border border-gray-100">
    ...
  </article>
</div>
```

### 2カラムグリッド

```html
<div class="grid grid-cols-1 md:grid-cols-2 gap-6">
  <div>左カラム</div>
  <div>右カラム</div>
</div>
```

### サイドバーレイアウト

```html
<div class="grid grid-cols-1 lg:grid-cols-4 gap-6">
  <!-- メインコンテンツ（3/4） -->
  <div class="lg:col-span-3">
    ...
  </div>

  <!-- サイドバー（1/4） -->
  <aside class="lg:col-span-1">
    ...
  </aside>
</div>
```

---

## ページパターン

### 一覧ページ

```html
<div class="min-h-screen bg-gray-50">
  <div class="max-w-6xl mx-auto px-4 py-8">

    <!-- ページヘッダー -->
    <header class="mb-8">
      <div class="flex items-center justify-between">
        <h1 class="text-2xl sm:text-3xl font-bold text-gray-900">投稿一覧</h1>
        <a href="/posts/new" class="bg-gray-900 text-white font-medium px-4 py-2 rounded-xl hover:bg-gray-800 transition-all">
          新規投稿
        </a>
      </div>
    </header>

    <!-- フィルターセクション -->
    <section class="mb-8">
      <div class="bg-white rounded-2xl shadow-sm border border-gray-100 p-6">
        <!-- 検索・フィルター -->
      </div>
    </section>

    <!-- 投稿グリッド -->
    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
      <!-- 投稿カード -->
    </div>

    <!-- ページネーション -->
    <div class="mt-10 flex justify-center">
      <!-- ページネーション -->
    </div>
  </div>
</div>
```

### 詳細ページ

```html
<div class="min-h-screen bg-gray-50">
  <div class="max-w-4xl mx-auto px-4 py-8">

    <!-- 戻るリンク -->
    <div class="mb-6">
      <a href="/posts" class="flex items-center gap-2 text-gray-600 hover:text-gray-900 transition-colors">
        <svg class="w-4 h-4"><!-- 戻るアイコン --></svg>
        一覧に戻る
      </a>
    </div>

    <!-- メインカード -->
    <article class="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden">
      <!-- YouTube埋め込み -->
      <div class="aspect-video">
        <iframe src="..." class="w-full h-full"></iframe>
      </div>

      <!-- コンテンツ -->
      <div class="p-6 lg:p-8">
        <!-- カテゴリ -->
        <div class="mb-4">
          <span class="text-xs bg-gray-100 text-gray-600 px-3 py-1 rounded-full">
            カテゴリ
          </span>
        </div>

        <!-- アクションプラン -->
        <div class="mb-6 p-4 bg-gray-50 rounded-xl">
          <h2 class="text-sm font-semibold text-gray-500 mb-2">アクションプラン</h2>
          <p class="text-gray-900">アクションプランの内容</p>
        </div>

        <!-- 達成ボタン -->
        <div class="pt-6 border-t border-gray-100">
          <button class="bg-gray-900 text-white font-semibold px-6 py-3 rounded-xl hover:bg-gray-800 transition-all">
            達成！
          </button>
        </div>
      </div>
    </article>

    <!-- コメントセクション -->
    <section class="mt-6 bg-white rounded-2xl shadow-sm border border-gray-100 p-6">
      <h2 class="text-lg font-bold text-gray-900 mb-6">コメント</h2>
      <!-- コメント一覧 -->
      <!-- コメントフォーム -->
    </section>
  </div>
</div>
```

### フォームページ

```html
<div class="min-h-screen bg-gray-50 py-8">
  <div class="max-w-2xl mx-auto px-4">

    <!-- フォームカード -->
    <div class="bg-white rounded-2xl shadow-sm border border-gray-100 p-6 lg:p-8">

      <!-- タイトル -->
      <div class="text-center mb-8">
        <h1 class="text-2xl font-bold text-gray-900">新規投稿</h1>
        <p class="mt-2 text-gray-600">YouTube動画から学びをアクションに変えよう</p>
      </div>

      <!-- フォーム -->
      <form class="space-y-6">
        <!-- YouTube URL -->
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-2">
            YouTube URL <span class="text-red-500">*</span>
          </label>
          <input type="url" class="w-full px-4 py-3 rounded-xl border border-gray-300 focus:border-gray-500 focus:ring-2 focus:ring-gray-200 transition-all" />
        </div>

        <!-- アクションプラン -->
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-2">
            アクションプラン <span class="text-red-500">*</span>
          </label>
          <textarea rows="4" class="w-full px-4 py-3 rounded-xl border border-gray-300 focus:border-gray-500 focus:ring-2 focus:ring-gray-200 transition-all"></textarea>
        </div>

        <!-- ボタン -->
        <div class="pt-6 space-y-3">
          <button type="submit" class="w-full bg-gray-900 text-white font-semibold px-6 py-4 rounded-xl hover:bg-gray-800 transition-all">
            投稿する
          </button>
          <a href="/posts" class="block w-full text-center text-gray-600 font-medium px-6 py-3 rounded-xl border border-gray-300 hover:bg-gray-50 transition-all">
            キャンセル
          </a>
        </div>
      </form>
    </div>
  </div>
</div>
```

---

## レスポンシブ対応

### ブレークポイント

| 名前 | 幅 | 用途 |
|------|-----|------|
| デフォルト | < 640px | モバイル |
| `sm:` | 640px | スマホ横向き |
| `md:` | 768px | タブレット |
| `lg:` | 1024px | デスクトップ |
| `xl:` | 1280px | 大画面 |

### モバイルファースト設計

```html
<!-- グリッド -->
<div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3">

<!-- パディング -->
<div class="p-4 md:p-6 lg:p-8">

<!-- テキストサイズ -->
<h1 class="text-2xl md:text-3xl lg:text-4xl">

<!-- 表示/非表示 -->
<div class="hidden md:block">デスクトップのみ</div>
<div class="md:hidden">モバイルのみ</div>
```

### レスポンシブパターン

#### ヘッダー

```html
<!-- デスクトップ: 横並び / モバイル: ハンバーガー -->
<nav class="hidden sm:flex items-center gap-4">...</nav>
<button class="sm:hidden">メニュー</button>
```

#### カードグリッド

```html
<!-- モバイル: 1列 / タブレット: 2列 / デスクトップ: 3列 -->
<div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4 md:gap-6">
```

#### 余白

```html
<!-- モバイルは狭く、デスクトップは広く -->
<div class="px-4 py-6 md:px-6 md:py-8 lg:px-8 lg:py-12">
```

---

## スペーシングガイド

### セクション間隔

```html
<!-- ページ内セクション間 -->
<section class="mb-8">...</section>
<section class="mb-8">...</section>

<!-- 大きなセクション間 -->
<section class="py-12">...</section>
```

### 要素間隔

```html
<!-- カード間 -->
<div class="grid gap-6">

<!-- リスト項目間 -->
<ul class="space-y-4">

<!-- インライン要素間 -->
<div class="flex items-center gap-4">
```

### ページ余白

```html
<!-- 標準 -->
<div class="px-4 py-8">

<!-- 広め -->
<div class="px-4 sm:px-6 lg:px-8 py-8 lg:py-12">
```

---

## FAB（フローティングアクションボタン）

モバイルでの新規投稿ボタン。

```html
<!-- モバイルのみ表示 -->
<div class="fixed bottom-6 right-6 z-50 sm:hidden">
  <a href="/posts/new" class="flex items-center justify-center w-14 h-14 bg-gray-900 text-white rounded-full shadow-lg hover:bg-gray-800 transition-all">
    <svg class="w-6 h-6"><!-- プラスアイコン --></svg>
  </a>
</div>
```

---

## モーダル

```html
<!-- オーバーレイ -->
<div class="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">

  <!-- モーダルコンテンツ -->
  <div class="bg-white rounded-2xl shadow-xl max-w-md w-full max-h-[90vh] overflow-y-auto">

    <!-- ヘッダー -->
    <div class="flex items-center justify-between p-6 border-b border-gray-100">
      <h2 class="text-lg font-bold text-gray-900">タイトル</h2>
      <button class="p-2 text-gray-500 hover:bg-gray-100 rounded-lg">
        <svg class="w-5 h-5"><!-- 閉じるアイコン --></svg>
      </button>
    </div>

    <!-- ボディ -->
    <div class="p-6">
      モーダルの内容
    </div>

    <!-- フッター -->
    <div class="flex justify-end gap-3 p-6 border-t border-gray-100">
      <button class="px-4 py-2 text-gray-600 hover:bg-gray-100 rounded-xl transition-all">
        キャンセル
      </button>
      <button class="px-4 py-2 bg-gray-900 text-white rounded-xl hover:bg-gray-800 transition-all">
        確定
      </button>
    </div>
  </div>
</div>
```

---

## ページネーション

```html
<nav class="flex items-center justify-center gap-2">
  <!-- 前へ -->
  <a href="#" class="p-2 text-gray-500 hover:bg-gray-100 rounded-lg transition-colors">
    <svg class="w-5 h-5"><!-- 左矢印 --></svg>
  </a>

  <!-- ページ番号 -->
  <a href="#" class="w-10 h-10 flex items-center justify-center text-gray-600 hover:bg-gray-100 rounded-lg transition-colors">1</a>
  <span class="w-10 h-10 flex items-center justify-center bg-gray-900 text-white rounded-lg font-medium">2</span>
  <a href="#" class="w-10 h-10 flex items-center justify-center text-gray-600 hover:bg-gray-100 rounded-lg transition-colors">3</a>

  <!-- 次へ -->
  <a href="#" class="p-2 text-gray-500 hover:bg-gray-100 rounded-lg transition-colors">
    <svg class="w-5 h-5"><!-- 右矢印 --></svg>
  </a>
</nav>
```

---

*最終更新: 2025-12-04*
