class Achievement < ApplicationRecord
  # ✅ 関連付け（リレーション）
  # Achievement は「ユーザーに属する」＝ user_id が必須
  belongs_to :user
  # Achievement は「投稿に属する」＝ post_id が必須
  belongs_to :post

  # ✅ バリデーション（入力チェック）
  # awarded_at（日付）が必ず存在することを保証
  validates :awarded_at, presence: true

  # 同じユーザーが、同じ投稿を、同じ日に
  # 2回以上達成できないようにする制約
  # → DBの一意インデックスと合わせて二重に守る
  validates :post_id, uniqueness: { 
    scope: [:user_id, :awarded_at],   # user_id と awarded_at を組み合わせてチェック
    message: "今日はすでに達成済みです"  # 重複したときに出すエラーメッセージ
  }
  
  # ✅ スコープ（よく使う検索条件をメソッド化）
  # Achievement.today と呼ぶと「今日の日付のレコード」だけを取得できる
  scope :today, -> { where(awarded_at: Date.current) }
end
