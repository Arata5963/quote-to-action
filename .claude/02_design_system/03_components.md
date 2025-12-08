# mitadake? UIコンポーネント設計

本ドキュメントでは、mitadake?で使用するUIコンポーネントのデザインパターンを定義します。

---

## ボタン

### プライマリボタン

メインアクション用。ウォームブラウン背景に白文字。

```html
<button class="bg-accent text-white font-semibold px-6 py-3 rounded-xl shadow-sm hover:bg-accent/90 hover:shadow-md active:bg-accent/80 transition-all">
  投稿する
</button>
```

**バリエーション**:

```html
<!-- 大サイズ -->
<button class="bg-accent text-white font-bold px-8 py-4 rounded-xl text-lg shadow-sm hover:bg-accent/90 hover:shadow-md transition-all">
  投稿する
</button>

<!-- 小サイズ -->
<button class="bg-accent text-white font-medium px-4 py-2 rounded-lg text-sm shadow-sm hover:bg-accent/90 transition-all">
  保存
</button>

<!-- 無効状態 -->
<button class="bg-accent/30 text-white/60 font-semibold px-6 py-3 rounded-xl cursor-not-allowed" disabled>
  投稿する
</button>
```

### セカンダリボタン

サブアクション用。白背景にウォームブラウンボーダー。

```html
<button class="bg-white text-accent font-semibold px-6 py-3 rounded-xl border-2 border-accent shadow-sm hover:bg-accent hover:text-white active:bg-accent/90 transition-all">
  キャンセル
</button>
```

### テキストボタン

軽いアクション用。背景なし。

```html
<button class="text-primary/80 font-medium px-4 py-2 rounded-lg hover:bg-accent/10 hover:text-accent transition-all">
  詳細を見る
</button>
```

### アイコンボタン

アイコンのみのボタン。

```html
<button class="p-2 text-primary/60 hover:text-accent hover:bg-accent/10 rounded-lg transition-all">
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
<article class="bg-white rounded-2xl shadow-sm border border-accent/20 overflow-hidden hover:shadow-md transition-shadow">
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
    <!-- ユーザー情報 -->
    <div class="flex items-center gap-3 mb-3">
      <img src="avatar.jpg" class="w-8 h-8 rounded-full" />
      <span class="text-sm font-medium text-primary">ユーザー名</span>
      <span class="text-xs text-primary/60">3時間前</span>
    </div>

    <!-- タイトル -->
    <h3 class="font-bold text-primary text-lg mb-2 line-clamp-2">
      動画タイトル
    </h3>

    <!-- アクションプラン -->
    <p class="text-primary/80 text-sm mb-4 line-clamp-2">
      アクションプランの内容
    </p>

    <!-- フッター -->
    <div class="flex items-center justify-between">
      <div class="flex items-center gap-4 text-primary/60 text-sm">
        <span class="flex items-center gap-1">
          <svg class="w-4 h-4"><!-- いいねアイコン --></svg>
          12
        </span>
        <span class="flex items-center gap-1">
          <svg class="w-4 h-4"><!-- コメントアイコン --></svg>
          3
        </span>
      </div>
      <span class="px-3 py-1 bg-accent/10 text-accent text-xs font-medium rounded-full">
        達成済み
      </span>
    </div>
  </div>
</article>
```

### シンプルカード

汎用的なカードコンポーネント。

```html
<div class="bg-white rounded-2xl shadow-sm border border-accent/20 p-5">
  <h3 class="font-semibold text-primary mb-2">タイトル</h3>
  <p class="text-primary/80 text-sm">内容テキスト</p>
</div>
```

---

## フォーム

### テキスト入力

```html
<div class="space-y-2">
  <label class="block text-sm font-medium text-primary">
    ラベル
  </label>
  <input
    type="text"
    class="w-full px-4 py-3 border-2 border-accent/30 rounded-xl text-primary placeholder-primary/40 focus:border-accent focus:ring-2 focus:ring-accent/20 focus:outline-none transition-colors"
    placeholder="プレースホルダー"
  />
</div>
```

### テキストエリア

```html
<div class="space-y-2">
  <label class="block text-sm font-medium text-primary">
    ラベル
  </label>
  <textarea
    rows="4"
    class="w-full px-4 py-3 border-2 border-accent/30 rounded-xl text-primary placeholder-primary/40 focus:border-accent focus:ring-2 focus:ring-accent/20 focus:outline-none transition-colors resize-none"
    placeholder="プレースホルダー"
  ></textarea>
</div>
```

### セレクト

```html
<div class="space-y-2">
  <label class="block text-sm font-medium text-primary">
    ラベル
  </label>
  <select class="w-full px-4 py-3 border-2 border-accent/30 rounded-xl text-primary bg-white focus:border-accent focus:ring-2 focus:ring-accent/20 focus:outline-none transition-colors">
    <option value="">選択してください</option>
    <option value="1">オプション1</option>
    <option value="2">オプション2</option>
  </select>
</div>
```

### チェックボックス

```html
<label class="flex items-center gap-3 cursor-pointer">
  <input
    type="checkbox"
    class="w-5 h-5 rounded border-2 border-accent/30 text-accent focus:ring-accent/20"
  />
  <span class="text-sm text-primary">ラベルテキスト</span>
</label>
```

### エラー状態

```html
<div class="space-y-2">
  <label class="block text-sm font-medium text-primary">
    ラベル
  </label>
  <input
    type="text"
    class="w-full px-4 py-3 border-2 border-red-500 rounded-xl text-primary placeholder-primary/40 focus:border-red-500 focus:ring-2 focus:ring-red-200 focus:outline-none"
  />
  <p class="text-sm text-red-600">エラーメッセージ</p>
</div>
```

---

## バッジ・タグ

### ステータスバッジ

```html
<!-- 達成済み -->
<span class="px-3 py-1 bg-accent/10 text-accent text-xs font-medium rounded-full">
  達成済み
</span>

<!-- 未達成 -->
<span class="px-3 py-1 bg-primary/10 text-primary/60 text-xs font-medium rounded-full">
  未達成
</span>

<!-- 成功 -->
<span class="px-3 py-1 bg-green-100 text-green-700 text-xs font-medium rounded-full">
  完了
</span>

<!-- エラー -->
<span class="px-3 py-1 bg-red-100 text-red-700 text-xs font-medium rounded-full">
  失敗
</span>
```

### カテゴリタグ

```html
<span class="inline-flex items-center gap-1 px-3 py-1 bg-cream text-primary text-xs font-medium rounded-full border border-accent/20">
  🎥 エンターテイメント
</span>
```

---

## ナビゲーション

### ヘッダー

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
        <a href="/posts" class="text-primary/80 hover:text-accent transition-colors">一覧</a>
        <button class="bg-accent text-white font-medium px-4 py-2 rounded-xl hover:bg-accent/90 transition-all">
          投稿
        </button>
      </nav>
    </div>
  </div>
</header>
```

### フッター

```html
<footer class="bg-white border-t border-accent/20">
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

### パンくずリスト

```html
<nav class="flex items-center gap-2 text-sm text-primary/60 mb-6">
  <a href="/" class="hover:text-accent transition-colors">ホーム</a>
  <span>/</span>
  <a href="/posts" class="hover:text-accent transition-colors">投稿一覧</a>
  <span>/</span>
  <span class="text-primary">投稿詳細</span>
</nav>
```

---

## 空状態

```html
<div class="text-center py-12">
  <div class="w-16 h-16 bg-accent/10 rounded-full flex items-center justify-center mx-auto mb-4">
    <svg class="w-8 h-8 text-accent"><!-- アイコン --></svg>
  </div>
  <h3 class="text-lg font-semibold text-primary mb-2">投稿がありません</h3>
  <p class="text-primary/60 mb-6">最初の投稿を作成しましょう</p>
  <button class="bg-accent text-white font-semibold px-6 py-3 rounded-xl hover:bg-accent/90 transition-all">
    投稿する
  </button>
</div>
```

---

## ローディング

### スピナー

```html
<div class="animate-spin w-6 h-6 border-2 border-accent/30 border-t-accent rounded-full"></div>
```

### スケルトン

```html
<div class="animate-pulse">
  <div class="aspect-video bg-accent/10 rounded-xl mb-4"></div>
  <div class="h-4 bg-accent/10 rounded w-3/4 mb-2"></div>
  <div class="h-4 bg-accent/10 rounded w-1/2"></div>
</div>
```

---

## アラート・メッセージ

### フラッシュメッセージ

```html
<!-- 成功 -->
<div class="bg-green-50 border-l-4 border-green-500 p-4 rounded-r-lg">
  <p class="text-green-700 font-medium">投稿を作成しました</p>
</div>

<!-- エラー -->
<div class="bg-red-50 border-l-4 border-red-500 p-4 rounded-r-lg">
  <p class="text-red-700 font-medium">エラーが発生しました</p>
</div>

<!-- 情報 -->
<div class="bg-cream border-l-4 border-accent p-4 rounded-r-lg">
  <p class="text-primary font-medium">お知らせがあります</p>
</div>
```

---

## 実装時の注意事項

### Railsフォームヘルパーとボタンスタイル

**問題**: Railsの`f.submit`や`button_to`ヘルパーでTailwindクラスを指定しても、スタイルが正しく適用されないことがある。

**解決策**: 明示的な`<button>`タグを使用し、必要に応じてインラインスタイルを併用する。

```erb
<%# NG: f.submit を使用 %>
<%= f.submit "送信", class: "bg-accent text-white px-5 py-2.5 rounded-xl" %>

<%# OK: 明示的な <button> タグを使用 %>
<button type="submit" class="bg-accent text-white px-5 py-2.5 rounded-xl">
  送信
</button>

<%# 確実: インラインスタイルを併用 %>
<button type="submit"
        class="rounded-xl text-sm font-medium"
        style="background-color: #8B7355; color: white; padding: 10px 20px;">
  送信
</button>
```

### 推奨カラーコード

インラインスタイルで使用する場合の対応表:

| Tailwindクラス | カラーコード |
|---------------|-------------|
| `bg-cream` | `#FAF8F5` |
| `bg-accent` | `#8B7355` |
| `text-primary` | `#4A4035` |
| `text-white` | `#FFFFFF` |
| `border-accent/20` | `rgba(139, 115, 85, 0.2)` |

---

*最終更新: 2025-12-08*
