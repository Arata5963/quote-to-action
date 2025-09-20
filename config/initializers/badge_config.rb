# config/initializers/badge_config.rb
BADGE_POOL = [
  { key: "book", name: "読書家", file: "badge_book.png", description: "読書からの気づきを大切にする人" },
  { key: "star", name: "スター", file: "badge_star.png", description: "継続的な実践者" },
  { key: "fire", name: "情熱", file: "badge_fire.png", description: "熱意あふれる実行者" },
  { key: "diamond", name: "ダイヤモンド", file: "badge_diamond.png", description: "貴重な気づきを得た人" },
  { key: "trophy", name: "達成者", file: "badge_trophy.png", description: "目標を達成する人" }
].freeze

def random_available_badge(user)
  # 今日既にバッジを獲得していたら nil を返す
  return nil if user.user_badges.where(awarded_at: Date.current.all_day).exists?
  
  # 全期間で未獲得のバッジから選択
  acquired_keys = user.user_badges.pluck(:badge_key)
  available = BADGE_POOL.reject { |badge| acquired_keys.include?(badge[:key]) }
  available.sample
end