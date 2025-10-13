# app/helpers/application_helper.rb
module ApplicationHelper
  # カテゴリのアイコンを返す
  def category_icon(category_key)
    icons = {
      "text" => "📝",
      "video" => "🎥",
      "audio" => "🎧",
      "conversation" => "💬",
      "experience" => "✨",
      "observation" => "👀",
      "other" => "📁"
    }
    icons[category_key.to_s] || "📁"
  end

  # カテゴリ名（絵文字なし）を返す
  def category_name_without_icon(category_key)
    Post.human_attribute_name("category.#{category_key}")
        .gsub(/[📝🎥🎧💬✨👀📁]/, "")
        .strip
  end

  # ★★★ OGP・メタタグのデフォルト設定（ここから追加） ★★★
  def default_meta_tags
    {
      site: 'ActionSpark',
      title: 'きっかけを行動に変える',
      reverse: true,
      charset: 'utf-8',
      description: '日常で得た「きっかけ」を記録し、具体的な行動に変換。小さな一歩から始める成長アプリ。',
      keywords: 'きっかけ,行動,習慣,成長,目標達成,自己改善',
      canonical: request.original_url,
      separator: '|',
      icon: [
        { href: '/favicon.ico' },
        { href: '/apple-touch-icon.png', rel: 'apple-touch-icon', sizes: '180x180', type: 'image/png' },
        { href: '/favicon-32x32.png', rel: 'icon', sizes: '32x32', type: 'image/png' },
        { href: '/favicon-16x16.png', rel: 'icon', sizes: '16x16', type: 'image/png' },
      ],
      og: {
        site_name: 'ActionSpark',
        title: :title,
        description: :description,
        type: 'website',
        url: request.original_url,
        image: "#{request.base_url}/ogp-image.svg",
        locale: 'ja_JP',
      },
      twitter: {
        card: 'summary_large_image',
        title: :title,
        description: :description,
        image: "#{request.base_url}/ogp-image.svg",
      }
    }
  end
  # ★★★ OGP・メタタグのデフォルト設定（ここまで追加） ★★★
end