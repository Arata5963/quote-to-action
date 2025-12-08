# mitadake? デザイントークン

本ドキュメントでは、mitadake?で使用するカラー、余白、角丸、影などの基本値を定義します。

---

## カラーパレット

### コンセプト

温かみと親しみやすさを重視した「ウォームベージュ系」の配色。
3色（＋白）のシンプルな構成で統一感を保つ。

### メインカラー（3色＋白）

| 用途 | Tailwind | HEX | 使用場面 | 使用比率 |
|------|----------|-----|----------|----------|
| ページ背景 | `bg-cream` | #FAF8F5 | ページ全体の背景 | 60% |
| カード背景 | `bg-white` | #FFFFFF | カード、モーダル、入力欄 | - |
| テキスト | `text-primary` | #4A4035 | 見出し、本文、すべてのテキスト | 25% |
| ボタン・強調 | `bg-accent` / `text-accent` | #8B7355 | ボタン、リンク、バッジ、アイコン | 15% |

### Tailwind設定

```javascript
// tailwind.config.js
module.exports = {
  theme: {
    extend: {
      colors: {
        cream: '#FAF8F5',
        primary: '#4A4035',
        accent: '#8B7355',
      }
    }
  }
}
```

### テキストカラーのバリエーション

透明度を使って濃淡を表現。追加の色は定義しない。

| 用途 | Tailwind | 効果 | 使用場面 |
|------|----------|------|----------|
| メインテキスト | `text-primary` | 100% | 見出し、重要テキスト |
| 本文テキスト | `text-primary/80` | 80% | 本文、説明文 |
| サブテキスト | `text-primary/60` | 60% | キャプション、補足情報 |
| ミューテッド | `text-primary/40` | 40% | プレースホルダー、無効状態 |

### ボーダーカラー

| 用途 | Tailwind | 効果 | 使用場面 |
|------|----------|------|----------|
| 標準ボーダー | `border-accent/20` | 20% | カード境界、区切り線 |
| 薄いボーダー | `border-accent/10` | 10% | 軽い区切り |
| フォーカス | `border-accent` | 100% | 入力欄フォーカス時 |

### プライマリボタン

| 状態 | 背景 | テキスト |
|------|------|----------|
| 通常 | `bg-accent` | `text-white` |
| ホバー | `bg-accent/90` | `text-white` |
| 押下 | `bg-accent/80` | `text-white` |
| 無効 | `bg-accent/30` | `text-white/60` |

### セカンダリボタン

| 状態 | 背景 | テキスト | ボーダー |
|------|------|----------|----------|
| 通常 | `bg-transparent` | `text-accent` | `border-accent` |
| ホバー | `bg-accent` | `text-white` | `border-accent` |

### システムカラー（変更なし）

ステータス表示にのみ使用。メインデザインには使わない。

| 用途 | Tailwind | HEX | 使用場面 |
|------|----------|-----|----------|
| 成功 | `text-green-600` / `bg-green-50` | #16A34A | 達成、完了、成功メッセージ |
| 警告 | `text-amber-600` / `bg-amber-50` | #D97706 | 注意、警告メッセージ |
| エラー | `text-red-600` / `bg-red-50` | #DC2626 | 削除、失敗、エラーメッセージ |
| 情報 | `text-blue-600` / `bg-blue-50` | #2563EB | リンク、情報メッセージ |

---

## カラー置き換え対応表

旧デザイン（モノトーン）から新デザイン（ウォームベージュ）への変換表。

| 旧（gray系） | 新（warm系） | 用途 |
|-------------|-------------|------|
| `bg-gray-50` | `bg-cream` | ページ背景 |
| `bg-white` | `bg-white` | カード背景（変更なし） |
| `text-gray-900` | `text-primary` | メインテキスト |
| `text-gray-600` | `text-primary/80` | 本文テキスト |
| `text-gray-500` | `text-primary/60` | サブテキスト |
| `text-gray-400` | `text-primary/40` | プレースホルダー |
| `bg-gray-900` | `bg-accent` | プライマリボタン |
| `bg-gray-800` | `bg-accent/90` | ボタンホバー |
| `text-gray-700` | `text-accent` | リンク、強調 |
| `border-gray-200` | `border-accent/20` | ボーダー |
| `border-gray-100` | `border-accent/10` | 薄いボーダー |
| `bg-gray-100` | `bg-cream` | ホバー背景 |
| `hover:bg-gray-100` | `hover:bg-accent/10` | ホバー状態 |

---

## タイポグラフィ

### フォントファミリー

```css
font-family: system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
```

Tailwind: デフォルト（`font-sans`）を使用

### フォントサイズ階層

| 用途 | Tailwind | サイズ | Weight | 使用場面 |
|------|----------|--------|--------|----------|
| ページタイトル | `text-2xl` / `text-3xl` | 24px / 30px | `font-bold` | ページ見出し |
| セクション見出し | `text-xl` | 20px | `font-semibold` | セクション区切り |
| カードタイトル | `text-lg` | 18px | `font-semibold` | カード内見出し |
| 本文 | `text-base` | 16px | `font-normal` | 通常テキスト |
| 小テキスト | `text-sm` | 14px | `font-normal` | 補足情報 |
| キャプション | `text-xs` | 12px | `font-medium` | タグ、バッジ、メタ情報 |

### 行間

| 用途 | Tailwind | 値 |
|------|----------|-----|
| 見出し | `leading-tight` | 1.25 |
| 本文 | `leading-relaxed` | 1.625 |
| 複数行テキスト | `leading-normal` | 1.5 |

---

## スペーシング（余白）

8px単位のゆったりとした余白設計。

### 基本単位

| Tailwind | 値 | 用途 |
|----------|-----|------|
| `space-1` / `gap-1` | 4px | 極小間隔（アイコンとテキスト） |
| `space-2` / `gap-2` | 8px | 小間隔（関連要素間） |
| `space-3` / `gap-3` | 12px | 中小間隔 |
| `space-4` / `gap-4` | 16px | 標準間隔（カード間、リスト項目間） |
| `space-5` / `gap-5` | 20px | 中間隔 |
| `space-6` / `gap-6` | 24px | 大間隔（セクション内要素間） |
| `space-8` / `gap-8` | 32px | セクション間 |
| `space-12` | 48px | 大セクション間 |

### パディング

| 用途 | Tailwind | 値 |
|------|----------|-----|
| カード内（標準） | `p-5` | 20px |
| カード内（大） | `p-6` | 24px |
| 入力フィールド | `px-4 py-3` | 16px / 12px |
| ボタン（標準） | `px-6 py-3` | 24px / 12px |
| ボタン（小） | `px-4 py-2` | 16px / 8px |
| タグ/バッジ | `px-3 py-1` | 12px / 4px |
| ページ余白 | `px-4` | 16px |

### マージン

| 用途 | Tailwind | 値 |
|------|----------|-----|
| カード間 | `gap-4` / `space-y-4` | 16px |
| セクション間 | `py-8` / `my-8` | 32px |
| 大セクション間 | `py-12` / `my-12` | 48px |
| 要素下余白 | `mb-2` / `mb-4` | 8px / 16px |

---

## 角丸（Border Radius）

大きめの角丸で柔らかく親しみやすい印象を与える。

| 用途 | Tailwind | 値 | 使用場面 |
|------|----------|-----|----------|
| 小 | `rounded-lg` | 8px | 小ボタン、入力フィールド内要素 |
| 標準 | `rounded-xl` | 12px | ボタン、入力フィールド、タグ |
| 大 | `rounded-2xl` | 16px | カード、モーダル、フィルターボックス |
| 特大 | `rounded-3xl` | 24px | 大きなカード、ヒーローセクション |
| 完全円 | `rounded-full` | 50% | アバター、バッジ、丸ボタン |

### 使い分け例

```html
<!-- ボタン -->
<button class="rounded-xl">標準ボタン</button>

<!-- カード -->
<div class="rounded-2xl">カード</div>

<!-- サムネイル -->
<div class="rounded-xl overflow-hidden">サムネイル</div>

<!-- アバター -->
<img class="rounded-full" />

<!-- タグ -->
<span class="rounded-full">タグ</span>
```

---

## 影（Box Shadow）

控えめな影でフラットながら奥行きのあるデザイン。

| 用途 | Tailwind | 使用場面 |
|------|----------|----------|
| なし | `shadow-none` | フラットな要素 |
| 極小 | `shadow-sm` | カード標準状態、軽い浮遊感 |
| 小 | `shadow` | ホバー時、強調要素 |
| 中 | `shadow-md` | ホバー時のフィードバック |
| 大 | `shadow-lg` | ドロップダウン、FAB |
| 特大 | `shadow-xl` | モーダル、重要なオーバーレイ |

### 影の使い分け

```html
<!-- カード（通常） -->
<div class="shadow-sm hover:shadow-md transition-shadow">
  カード
</div>

<!-- モーダル -->
<div class="shadow-xl">
  モーダル
</div>

<!-- FAB（フローティングボタン） -->
<button class="shadow-lg">
  +
</button>
```

---

## ボーダー

| 用途 | Tailwind | 使用場面 |
|------|----------|----------|
| カード境界 | `border border-accent/20` | カードの軽い境界 |
| 入力フィールド | `border-2 border-accent/30` | フォーム要素 |
| セパレーター | `border-t border-accent/20` | セクション区切り |
| フォーカス | `focus:border-accent` | フォーカス状態 |

---

## トランジション

| 用途 | Tailwind | 使用場面 |
|------|----------|----------|
| 全般 | `transition-all` | 複数プロパティの変化 |
| 色変化 | `transition-colors` | 背景色、テキスト色の変化 |
| 影変化 | `transition-shadow` | シャドウの変化 |
| 速度 | `duration-200` | 200ms（デフォルト） |

### 標準トランジション

```html
<!-- ボタン -->
<button class="transition-all hover:bg-accent/90">

<!-- カード -->
<div class="transition-shadow hover:shadow-md">

<!-- リンク -->
<a class="transition-colors hover:text-accent">
```

---

## ブレークポイント

| 名前 | Tailwind | 値 | 用途 |
|------|----------|-----|------|
| モバイル | デフォルト | < 640px | スマートフォン |
| sm | `sm:` | 640px | スマホ横向き |
| md | `md:` | 768px | タブレット |
| lg | `lg:` | 1024px | デスクトップ |
| xl | `xl:` | 1280px | 大画面 |
| 2xl | `2xl:` | 1536px | 超大画面 |

---

## アクセシビリティ

### コントラスト比

- 通常テキスト: 4.5:1 以上
- 大きなテキスト（18px以上）: 3:1 以上

### 推奨組み合わせ

| 背景 | テキスト | コントラスト比 |
|------|----------|---------------|
| `bg-cream` (#FAF8F5) | `text-primary` (#4A4035) | 7.2:1 ✅ |
| `bg-white` | `text-primary` (#4A4035) | 8.1:1 ✅ |
| `bg-accent` (#8B7355) | `text-white` | 4.5:1 ✅ |
| `bg-cream` (#FAF8F5) | `text-accent` (#8B7355) | 3.8:1 ✅ (大きなテキスト) |

### フォーカス状態

```html
<button class="focus:outline-none focus:ring-2 focus:ring-accent/50 focus:ring-offset-2">
```

### 最小タッチターゲット

- 最小サイズ: 44px × 44px
- ボタン: `min-h-[44px]` または `py-3`

---

*最終更新: 2025-12-08*
