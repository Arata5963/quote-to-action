# app/helpers/badges_helper.rb
module BadgesHelper
  def badge_key_for(total)
    idx = [total.to_i, 4].min
    "badge_#{idx}.png"
  end

  def post_badge_tag(post, **opts)
    total = post.achievements.count
    key   = badge_key_for(total)
    image_tag asset_path("badges/#{key}"),
              { alt: "Badge for Post (#{total})" }.merge(opts)
  end
end
