# app/helpers/application_helper.rb
module ApplicationHelper
  # カテゴリ名を返す
  def category_name_without_icon(category_key)
    I18n.t("enums.post.category.#{category_key}", default: category_key.to_s.humanize)
  end

  # ★★★ OGP・メタタグのデフォルト設定（ここから追加） ★★★
  def default_meta_tags
    {
      site: "mitadake?",
      title: "見て終わり→やってみる",
      reverse: true,
      charset: "utf-8",
      description: "YouTube動画から得た学びを具体的なアクションに変換。見て終わりを、やってみるに変える。",
      keywords: "YouTube,学習,行動,習慣,目標達成,自己改善,アクションプラン",
      canonical: request.original_url,
      separator: "|",
      icon: [
        { href: "/favicon.ico" },
        { href: "/apple-touch-icon.png", rel: "apple-touch-icon", sizes: "180x180", type: "image/png" },
        { href: "/favicon-32x32.png", rel: "icon", sizes: "32x32", type: "image/png" },
        { href: "/favicon-16x16.png", rel: "icon", sizes: "16x16", type: "image/png" }
      ],
      og: {
        site_name: "mitadake?",
        title: :title,
        description: :description,
        type: "website",
        url: request.original_url,
        image: "#{request.base_url}/ogp-image.svg",
        locale: "ja_JP"
      },
      twitter: {
        card: "summary_large_image",
        title: :title,
        description: :description,
        image: "#{request.base_url}/ogp-image.svg"
      }
    }
  end
  # ★★★ OGP・メタタグのデフォルト設定（ここまで追加） ★★★
end
