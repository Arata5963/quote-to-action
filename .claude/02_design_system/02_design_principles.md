# ActionSpark デザイン原則

本ドキュメントでは、ActionSparkのデザイン方針、ガイドライン、禁止事項を定義します。

---

## コンセプト

### アプリ概要

**ActionSpark** - YouTube動画から得た学びを「アクションプラン」に変換し、実践を支援する行動変革アプリ

### キャッチコピー

> **「見て終わり」を「やってみる」に変える**

### デザインの方向性

| 項目 | 方針 |
|------|------|
| 雰囲気 | 柔らかく親しみやすい、余白たっぷりでゆったり |
| カラー | モノトーン（黒・グレー・白）のみ使用 |
| 重視する要素 | YouTubeサムネイルを大きく表示 |
| ナビゲーション | ヘッダーメニュー（下部タブバーなし） |

---

## 5つの基本原則

### 1. 余白を大切に

要素間にゆとりを持たせ、窮屈さを感じさせない。

```html
<!-- 良い例：ゆったりした余白 -->
<div class="p-6 space-y-4">
  <h2 class="mb-4">タイトル</h2>
  <p>本文</p>
</div>

<!-- 悪い例：詰め込みすぎ -->
<div class="p-2 space-y-1">
  <h2 class="mb-1">タイトル</h2>
  <p>本文</p>
</div>
```

**推奨余白**:
- カード内: `p-5` / `p-6`
- 要素間: `space-y-4` / `gap-4`
- セクション間: `py-8` / `py-12`

### 2. サムネイル重視

YouTube動画のサムネイルを大きく見せることで、視覚的なインパクトを与える。

```html
<!-- サムネイルは必ず aspect-video で16:9表示 -->
<div class="aspect-video rounded-xl overflow-hidden">
  <img src="thumbnail.jpg" class="w-full h-full object-cover" />
</div>
```

**ルール**:
- アスペクト比は `aspect-video`（16:9）を使用
- 角丸は `rounded-xl` で統一
- `object-cover` でトリミング表示

### 3. モノトーン統一

黒・グレー・白で落ち着いた印象を与える。彩度の高い色は避ける。

| 用途 | 使用する色 |
|------|-----------|
| 背景 | `gray-50`, `white` |
| テキスト | `gray-900`, `gray-600`, `gray-500` |
| ボーダー | `gray-200`, `gray-100` |
| ボタン | `gray-900`（プライマリ）、`white`（セカンダリ） |

**システムカラー**はステータス表示にのみ使用:
- 成功: `green-600`
- エラー: `red-600`
- 警告: `amber-600`
- 情報: `blue-600`

### 4. 角丸で柔らかく

大きめの角丸で親しみやすさを演出。

| コンポーネント | 角丸 |
|---------------|------|
| ボタン | `rounded-xl` |
| カード | `rounded-2xl` |
| 入力フィールド | `rounded-xl` |
| サムネイル | `rounded-xl` |
| タグ/バッジ | `rounded-full` |
| アバター | `rounded-full` |

### 5. 影は控えめ

`shadow-sm` を基本とし、ホバー時のフィードバックで `shadow-md` を使用。

```html
<!-- カードの影 -->
<div class="shadow-sm hover:shadow-md transition-shadow">
  カード内容
</div>
```

**影の使い分け**:
- 通常状態: `shadow-sm`
- ホバー状態: `shadow-md`
- モーダル: `shadow-xl`
- 影なし: フラットな要素

---

## アクセシビリティ

### コントラスト比

WCAG 2.1 AA基準を満たすコントラスト比を確保。

| 基準 | 要件 |
|------|------|
| 通常テキスト | 4.5:1 以上 |
| 大きなテキスト（18px以上） | 3:1 以上 |
| UI要素 | 3:1 以上 |

### タッチターゲット

モバイルでの操作性を確保。

```html
<!-- 最小44pxを確保 -->
<button class="min-h-[44px] px-4 py-3">
  ボタン
</button>
```

**ルール**:
- 最小タッチターゲット: 44px × 44px
- ボタンは `py-3` 以上を使用
- タップ可能な要素間の余白を十分に取る

### フォーカス状態

キーボード操作時にフォーカスを明確に表示。

```html
<button class="focus:outline-none focus:ring-2 focus:ring-gray-400 focus:ring-offset-2">
  ボタン
</button>

<input class="focus:border-gray-500 focus:ring-2 focus:ring-gray-200" />
```

### 色だけに依存しない

状態の伝達に色だけを使わない。アイコンやテキストを併用。

```html
<!-- 良い例：アイコン + テキスト + 色 -->
<div class="text-green-600 flex items-center gap-2">
  <svg>✓</svg>
  <span>達成済み</span>
</div>

<!-- 悪い例：色だけ -->
<div class="text-green-600">●</div>
```

---

## 禁止事項

### 色に関する禁止

| 禁止事項 | 理由 |
|----------|------|
| 黄色の使用 | 旧デザインとの差別化、モノトーン統一のため |
| 派手なグラデーション | 落ち着いた印象を損なう |
| 彩度の高い背景色 | モノトーンコンセプトに反する |

### レイアウトに関する禁止

| 禁止事項 | 理由 |
|----------|------|
| 影の多用 | デザインが重くなる |
| 小さすぎる文字（14px未満） | 可読性低下 |
| 詰め込みすぎのレイアウト | 余白重視のコンセプトに反する |
| 下部タブバー | ヘッダーメニュー方式を採用 |

### コントラストに関する禁止

| 禁止事項 | 代替案 |
|----------|--------|
| `gray-300` on `white` | `gray-600` 以上を使用 |
| `gray-400` for 本文 | `gray-600` を使用 |
| 薄い背景に薄いテキスト | コントラスト比を確認 |

---

## インタラクション設計

### ホバー状態

```css
/* 標準的なホバー効果 */
transition-all
hover:bg-gray-100      /* 背景色変化 */
hover:shadow-md        /* 影の強調 */
hover:text-gray-900    /* テキスト色の強調 */
```

### アクティブ状態

```css
active:bg-gray-200     /* 押下時の背景 */
active:scale-95        /* 軽い縮小 */
```

### 無効状態

```css
disabled:opacity-50
disabled:cursor-not-allowed
disabled:bg-gray-100
```

### トランジション

すべてのインタラクティブ要素にトランジションを適用。

```html
<button class="transition-all duration-200">
<div class="transition-shadow duration-200">
<a class="transition-colors duration-200">
```

---

## レスポンシブデザイン

### モバイルファースト

小さい画面から設計し、大きい画面に拡張。

```html
<!-- モバイルファースト -->
<div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3">
```

### ブレークポイント

| 名前 | 幅 | 用途 |
|------|-----|------|
| デフォルト | < 640px | モバイル |
| `sm` | 640px | スマホ横向き |
| `md` | 768px | タブレット |
| `lg` | 1024px | デスクトップ |

### タッチデバイス考慮

- ホバー効果はあくまで補助
- タップで完結する操作設計
- スワイプなどのジェスチャーは慎重に

---

## 一貫性の維持

### 命名規則

| 対象 | 規則 | 例 |
|------|------|-----|
| CSSクラス | ケバブケース | `card-title`, `btn-primary` |
| コンポーネント | パスカルケース | `PostCard`, `LikeButton` |
| 状態 | 接尾辞 | `-hover`, `-active`, `-disabled` |

### コンポーネントの再利用

同じ見た目の要素は必ず同じスタイルを使用。

```html
<!-- すべてのカードで統一 -->
<div class="bg-white rounded-2xl shadow-sm border border-gray-100 p-5">
```

### デザイントークンの参照

色やサイズは `01_design_tokens.md` で定義された値を使用。
ハードコードした値は使わない。

---

*最終更新: 2025-12-04*
