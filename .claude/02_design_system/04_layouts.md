# mitadake? レイアウトシステム

本ドキュメントでは、mitadake?で使用するレイアウトパターン、グリッドシステム、レスポンシブ対応を定義します。

---

## 基本構造

### ページレイアウト

```html
<div class="min-h-screen bg-cream flex flex-col">
  <!-- ヘッダー -->
  <header class="bg-white border-b border-accent/20 sticky top-0 z-50">
    ...
  </header>

  <!-- メインコンテンツ -->
  <main class="flex-1">
    <div class="max-w-4xl mx-auto px-4 py-8">
      ...
    </div>
  </main>

  <!-- フッター -->
  <footer class="bg-white border-t border-accent/20">
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
<header class="bg-white border-b border-accent/20 sticky top-0 z-50">
  <div class="max-w-screen-xl mx-auto px-4">
    <div class="flex items-center justify-between h-16">

      <!-- ロゴ -->
      <a href="/" class="flex items-center gap-2">
        <div class="w-8 h-8 bg-accent rounded-lg flex items-center justify-center">
          <span class="text-white font-bold">?</span>
        </div>
        <span class="text-xl font-bold text-primary">mitadake?</span>
      </a>

      <!-- ナビゲーション -->
      <nav class="flex items-center gap-4">
        <!-- デスクトップメニュー -->
        <div class="hidden sm:flex items-center gap-4">
          <a href="/posts" class="text-primary/80 hover:text-accent transition-colors">
            一覧
          </a>
        </div>

        <!-- 投稿ボタン -->
        <a href="/posts/new" class="bg-accent text-white font-medium px-4 py-2 rounded-xl hover:bg-accent/90 transition-all">
          投稿
        </a>

        <!-- ハンバーガーメニュー（モバイル） -->
        <button class="sm:hidden p-2 text-primary/60 hover:bg-accent/10 rounded-lg">
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
<footer class="bg-white border-t border-accent/20 mt-auto">
  <div class="max-w-screen-xl mx-auto px-4 py-8">
    <div class="flex flex-col sm:flex-row items-center justify-between gap-4">

      <!-- ロゴ -->
      <div class="flex items-center gap-2">
        <div class="w-6 h-6 bg-accent rounded-md flex items-center justify-center">
          <span class="text-white font-bold text-sm">?</span>
        </div>
        <span class="font-semibold text-primary">mitadake?</span>
      </div>

      <!-- リンク -->
      <nav class="flex items-center gap-6 text-sm">
        <a href="/terms" class="text-primary/60 hover:text-accent transition-colors">
          利用規約
        </a>
        <a href="/privacy" class="text-primary/60 hover:text-accent transition-colors">
          プライバシー
        </a>
        <a href="/contact" class="text-primary/60 hover:text-accent transition-colors">
          お問い合わせ
        </a>
      </nav>
    </div>

    <div class="mt-6 pt-6 border-t border-accent/10 text-center">
      <p class="text-sm text-primary/40">&copy; 2025 mitadake?</p>
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
  <article class="bg-white rounded-2xl shadow-sm border border-accent/20">
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
<div class="min-h-screen bg-cream">
  <div class="max-w-6xl mx-auto px-4 py-8">

    <!-- ページヘッダー -->
    <header class="mb-8">
      <div class="flex items-center justify-between">
        <h1 class="text-2xl sm:text-3xl font-bold text-primary">投稿一覧</h1>
        <a href="/posts/new" class="bg-accent text-white font-medium px-4 py-2 rounded-xl hover:bg-accent/90 transition-all">
          新規投稿
        </a>
      </div>
    </header>

    <!-- フィルターセクション -->
    <section class="mb-8">
      <div class="bg-white rounded-2xl shadow-sm border border-accent/20 p-6">
        <!-- フィルター内容 -->
      </div>
    </section>

    <!-- カードグリッド -->
    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
      <!-- カード -->
    </div>

    <!-- ページネーション -->
    <nav class="mt-8 flex justify-center">
      <!-- ページネーション -->
    </nav>

  </div>
</div>
```

### 詳細ページ

```html
<div class="min-h-screen bg-cream">
  <div class="max-w-4xl mx-auto px-4 py-8">

    <!-- パンくず -->
    <nav class="mb-6 text-sm text-primary/60">
      <a href="/" class="hover:text-accent">ホーム</a>
      <span class="mx-2">/</span>
      <a href="/posts" class="hover:text-accent">投稿一覧</a>
      <span class="mx-2">/</span>
      <span class="text-primary">詳細</span>
    </nav>

    <!-- メインカード -->
    <article class="bg-white rounded-2xl shadow-sm border border-accent/20 overflow-hidden">
      <!-- コンテンツ -->
    </article>

    <!-- 関連セクション -->
    <section class="mt-8">
      <h2 class="text-xl font-bold text-primary mb-4">コメント</h2>
      <div class="bg-white rounded-2xl shadow-sm border border-accent/20 p-6">
        <!-- コメント -->
      </div>
    </section>

  </div>
</div>
```

### フォームページ

```html
<div class="min-h-screen bg-cream">
  <div class="max-w-2xl mx-auto px-4 py-8">

    <!-- ページタイトル -->
    <h1 class="text-2xl font-bold text-primary mb-8">新規投稿</h1>

    <!-- フォームカード -->
    <div class="bg-white rounded-2xl shadow-sm border border-accent/20 p-6">
      <form class="space-y-6">
        <!-- フォームフィールド -->

        <!-- ボタン -->
        <div class="flex items-center gap-4 pt-4">
          <button type="submit" class="bg-accent text-white font-semibold px-6 py-3 rounded-xl hover:bg-accent/90 transition-all">
            投稿する
          </button>
          <a href="/posts" class="text-primary/60 font-medium px-6 py-3 rounded-xl hover:bg-accent/10 transition-all">
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

| 名前 | Tailwind | 値 | 用途 |
|------|----------|-----|------|
| モバイル | デフォルト | < 640px | スマートフォン |
| sm | `sm:` | 640px | スマホ横向き |
| md | `md:` | 768px | タブレット |
| lg | `lg:` | 1024px | デスクトップ |
| xl | `xl:` | 1280px | 大画面 |

### レスポンシブパターン

```html
<!-- テキストサイズ -->
<h1 class="text-2xl sm:text-3xl lg:text-4xl">

<!-- パディング -->
<div class="px-4 sm:px-6 lg:px-8">

<!-- グリッド -->
<div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3">

<!-- 表示/非表示 -->
<div class="hidden sm:block">デスクトップのみ</div>
<div class="sm:hidden">モバイルのみ</div>

<!-- フレックス方向 -->
<div class="flex flex-col sm:flex-row">
```

---

## 間隔・余白ガイド

### セクション間

```html
<!-- 大きなセクション間 -->
<section class="py-12">

<!-- 通常のセクション間 -->
<section class="py-8">

<!-- 小さなセクション間 -->
<section class="py-6">
```

### 要素間

```html
<!-- カード間 -->
<div class="space-y-4">

<!-- グリッドギャップ -->
<div class="gap-4 md:gap-6">

<!-- リスト項目間 -->
<ul class="space-y-2">
```

---

## Z-Index管理

| 用途 | 値 | Tailwind |
|------|-----|----------|
| ベースコンテンツ | 0 | `z-0` |
| カードホバー | 10 | `z-10` |
| ドロップダウン | 20 | `z-20` |
| スティッキーヘッダー | 50 | `z-50` |
| モーダル背景 | 40 | `z-40` |
| モーダル | 50 | `z-50` |
| トースト | 60 | `z-[60]` |

---

*最終更新: 2025-12-08*
