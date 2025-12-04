module BadgesHelper
  def post_badge_tag(post, **opts)
    achieved = post.achieved?

    svg_content = if achieved
      # 達成済み: 塗りつぶし星（黄色）
      '<svg viewBox="0 0 24 24" fill="currentColor" class="text-yellow-500">
        <polygon points="12,2 15.09,8.26 22,9.27 17,14.14 18.18,21.02 12,17.77 5.82,21.02 7,14.14 2,9.27 8.91,8.26"/>
      </svg>'.html_safe
    else
      # 未達成: 空の星（グレー）
      '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" class="text-gray-400">
        <polygon points="12,2 15.09,8.26 22,9.27 17,14.14 18.18,21.02 12,17.77 5.82,21.02 7,14.14 2,9.27 8.91,8.26"/>
      </svg>'.html_safe
    end

    content_tag(:div, svg_content, **opts)
  end
end
