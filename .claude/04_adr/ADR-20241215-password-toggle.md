# ADR-20241215: パスワード表示/非表示機能

## ステータス
承認済み

## コンテキスト

パスワード入力時のユーザビリティを向上させるため、パスワードの表示/非表示を切り替える機能を実装する。

### 現状
- Deviseによる認証機能実装済み
- パスワードフィールドは `type="password"` で固定（●●●●表示のみ）
- ユーザーが誤入力に気づきにくく、再入力の手間が発生

### 要件
- **適用範囲**: 全パスワード入力欄（新規登録・ログイン・パスワード変更・プロフィール編集）
- **アイコン**: Heroicons SVG（Tailwind公式、既存デザインと統一）
- **配置**: 入力欄の右端内側（絶対配置、業界標準のUI）
- **実装方法**: Stimulus Controller（Hotwireとの親和性）
- **アクセシビリティ**: スクリーンリーダー対応、キーボード操作可能

## 決定

**Stimulus Controller + 再利用可能なパーシャルで実装**

### 技術選定理由

| 観点 | 評価 |
|------|------|
| 既存技術スタック | ◎ Stimulus既に使用中 |
| 実装コスト | ◎ 30行のコントローラ + 60行のパーシャル |
| 保守性 | ◎ パーシャルで全画面統一 |
| パフォーマンス | ◎ gem不要、軽量 |
| アクセシビリティ | ◎ ARIA属性対応 |

### 不採用案

1. **jQuery Plugin**
   - 理由: jQueryを使用していない、依存関係増加

2. **素のJavaScript（Stimulusなし）**
   - 理由: 既存のStimulusエコシステムから外れる、統一感喪失

3. **CSS only（:checked疑似クラス）**
   - 理由: パスワードフィールドにチェックボックスを配置する必要があり、UX低下

## 実装詳細

### ファイル構成
```
app/
├── javascript/
│   └── controllers/
│       └── password_toggle_controller.js    # Stimulus Controller
└── views/
    ├── shared/
    │   └── _password_field.html.erb         # 再利用可能なパーシャル
    └── devise/
        ├── registrations/
        │   ├── new.html.erb                 # 新規登録（更新）
        │   └── edit.html.erb                # プロフィール編集（更新）
        ├── sessions/
        │   └── new.html.erb                 # ログイン（更新）
        └── passwords/
            └── edit.html.erb                # パスワードリセット（更新）

spec/
└── system/
    └── password_toggle_spec.rb              # System Spec（後で作成）
```

### Stimulus Controller仕様

- **targets**: `input`, `iconShow`, `iconHide`
- **actions**: `toggle()`, `showPassword()`, `hidePassword()`
- **初期化**: `connect()`でパスワード非表示状態にセット

### パーシャル仕様

**パラメータ:**
- `form`: フォームビルダー（必須）
- `field_name`: フィールド名（必須）
- `label_text`: ラベル表示テキスト（必須）
- `placeholder`: プレースホルダー（オプション）
- `autocomplete`: autocomplete属性（オプション）
- `show_hint`: パスワード要件ヒント表示（オプション）
- `minimum_length`: 最小文字数（オプション）

### アクセシビリティ対応

- **aria-label**: ボタンに「パスワードを表示/非表示」と明示
- **aria-hidden**: SVGアイコンは装飾扱い
- **type="button"**: フォーム送信を防ぐ
- **キーボード操作**: Tabキーで移動可能
- **focus:ring**: フォーカス時の視覚的フィードバック

## 影響

### 正の影響
- ✅ パスワード誤入力の削減
- ✅ ユーザー体験の向上（業界標準UI）
- ✅ 全画面で統一されたUX
- ✅ アクセシビリティ向上

### 負の影響
- ⚠️ セキュリティリスク: 肩越しに見られる可能性（物理的脅威）
  - 対策: ユーザーの判断に委ねる、公共の場での使用は自己責任

### 考慮事項
- **モバイル対応**: タッチターゲットサイズ確保（44x44px以上推奨）
- **ブラウザ互換性**: モダンブラウザのみサポート（IE11未対応でOK）
- **パフォーマンス**: DOM操作は最小限、リフロー/リペイントなし

## テスト戦略

### System Spec（RSpec + Capybara + Selenium）
- ✅ 各ページでボタンが表示されるか
- ✅ クリックでtype属性が切り替わるか（password ⇔ text）
- ✅ アイコンが正しく切り替わるか
- ✅ aria-label が設定されているか
- ✅ キーボード操作が可能か（Tabで移動）

### カバレッジ目標
- System Spec: 全パスワード入力画面をカバー
- 手動テスト: ブラウザで実際の動作確認

## 関連ドキュメント

- [Stimulus Handbook](https://stimulus.hotwired.dev/)
- [Heroicons](https://heroicons.com/)
- [WCAG 2.1 Guidelines](https://www.w3.org/WAI/WCAG21/quickref/)

## 変更履歴

| 日付 | 変更内容 | 変更者 |
|------|----------|--------|
| 2024-12-15 | 初版作成 | 新 |
