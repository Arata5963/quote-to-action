# spec/helpers/badges_helper_spec.rb
require 'rails_helper'

RSpec.describe BadgesHelper, type: :helper do
  let(:user) { create(:user) }

  # 「1日1回」ユニーク制約: user_id + post_id + awarded_at
  # → awarded_at を日ごとにずらして n 件作る
  def post_with_achievements(n)
    post = create(:post, user: user)
    n.times do |i|
      create(
        :achievement,
        user: user,
        post: post,
        awarded_at: Date.current - i.days
      )
    end
    post.reload
  end

  it '0回: SVGを返す' do
    html = helper.post_badge_tag(post_with_achievements(0))
    expect(html).to include('<svg')
  end

  it '1回: SVGを返す' do
    html = helper.post_badge_tag(post_with_achievements(1))
    expect(html).to include('<svg')
  end

  it '2回: SVGを返す' do
    html = helper.post_badge_tag(post_with_achievements(2))
    expect(html).to include('<svg')
  end

  it '3回: SVGを返す' do
    html = helper.post_badge_tag(post_with_achievements(3))
    expect(html).to include('<svg')
  end

  it '4回以上: SVGを返す' do
    html = helper.post_badge_tag(post_with_achievements(5))
    expect(html).to include('<svg')
  end

  it 'class オプションが反映される' do
    html = helper.post_badge_tag(post_with_achievements(1), class: 'text-yellow-500')
    expect(html).to include('text-yellow-500')
  end
end
