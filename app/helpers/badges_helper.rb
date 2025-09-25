# 実装中
module BadgesHelper
  def post_badge_tag(post, **opts)
    achievement_count = post.achievements.count

    svg_content = case achievement_count
    when 0
                    # 0回: 空の星（アウトライン）
                    '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                      <polygon points="12,2 15.09,8.26 22,9.27 17,14.14 18.18,21.02 12,17.77 5.82,21.02 7,14.14 2,9.27 8.91,8.26"/>
                    </svg>'.html_safe
    when 1
                    # 1回: 塗りつぶし星
                    '<svg viewBox="0 0 24 24" fill="currentColor">
                      <polygon points="12,2 15.09,8.26 22,9.27 17,14.14 18.18,21.02 12,17.77 5.82,21.02 7,14.14 2,9.27 8.91,8.26"/>
                    </svg>'.html_safe
    when 2
                    # 2回: 炎
                    '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                      <path d="M8.5 14.5A2.5 2.5 0 0 0 11 12c0-1.38.5-2 1-3 1-1.5 2-2 2-2s1.75.75 3 2.5c.15.25.75 1.25.75 2.5A5.5 5.5 0 0 1 12.25 17H8.5z"/>
                      <path d="M10.5 12V7"/>
                    </svg>'.html_safe
    when 3
                    # 3回: トロフィー
                    '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                      <line x1="8" y1="21" x2="16" y2="21"/>
                      <line x1="12" y1="17" x2="12" y2="21"/>
                      <path d="M7 4V2a1 1 0 0 1 1-1h8a1 1 0 0 1 1 1v2"/>
                      <path d="M7 4h10v9a5 5 0 0 1-10 0V4z"/>
                    </svg>'.html_safe
    else
                    # 4回以上: 王冠
                    '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                      <path d="M6 3h12l4 6-10 13L2 9z"/>
                      <path d="M11 3L8 9l4 13 4-13-3-6"/>
                    </svg>'.html_safe
    end

    content_tag(:div, svg_content, **opts.merge(class: "#{opts[:class]} text-current"))
  end
end
