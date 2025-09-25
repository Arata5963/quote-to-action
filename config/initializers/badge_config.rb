# config/initializers/badge_config.rb
BADGE_POOL = [
  {
    key: "book",
    name: "読書家",
    description: "読書からの気づきを大切にする人",
    svg: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
      <path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20"/>
      <path d="M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2z"/>
      <line x1="10" y1="8" x2="16" y2="8"/>
      <line x1="10" y1="12" x2="16" y2="12"/>
      <line x1="10" y1="16" x2="14" y2="16"/>
    </svg>'.html_safe
  },
  {
    key: "star",
    name: "スター",
    description: "継続的な実践者",
    svg: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
      <polygon points="12,2 15.09,8.26 22,9.27 17,14.14 18.18,21.02 12,17.77 5.82,21.02 7,14.14 2,9.27 8.91,8.26"/>
    </svg>'.html_safe
  },
  {
    key: "fire",
    name: "情熱",
    description: "熱意あふれる実行者",
    svg: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
      <path d="M8.5 14.5A2.5 2.5 0 0 0 11 12c0-1.38.5-2 1-3 1-1.5 2-2 2-2s1.75.75 3 2.5c.15.25.75 1.25.75 2.5A5.5 5.5 0 0 1 12.25 17H8.5z"/>
      <path d="M10.5 12V7"/>
    </svg>'.html_safe
  },
  {
    key: "diamond",
    name: "ダイヤモンド",
    description: "貴重な気づきを得た人",
    svg: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
      <path d="M6 3h12l4 6-10 13L2 9z"/>
      <path d="M11 3 8 9l4 13 4-13-3-6"/>
    </svg>'.html_safe
  },
  {
    key: "trophy",
    name: "達成者",
    description: "目標を達成する人",
    svg: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
      <line x1="8" y1="21" x2="16" y2="21"/>
      <line x1="12" y1="17" x2="12" y2="21"/>
      <path d="M7 4V2a1 1 0 0 1 1-1h8a1 1 0 0 1 1 1v2"/>
      <path d="M7 4h10v9a5 5 0 0 1-10 0V4z"/>
      <path d="M16 4h2a2 2 0 0 1 0 4h-2"/>
      <path d="M8 4H6a2 2 0 0 0 0 4h2"/>
    </svg>'.html_safe
  }
].freeze

def random_available_badge(user)
  # 今日既にバッジを獲得していたら nil を返す
  return nil if user.user_badges.where(awarded_at: Date.current.all_day).exists?

  # 全期間で未獲得のバッジから選択
  acquired_keys = user.user_badges.pluck(:badge_key)
  available = BADGE_POOL.reject { |badge| acquired_keys.include?(badge[:key]) }
  available.sample
end
