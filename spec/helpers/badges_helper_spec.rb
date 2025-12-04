# spec/helpers/badges_helper_spec.rb
require 'rails_helper'

RSpec.describe BadgesHelper, type: :helper do
  let(:user) { create(:user) }

  describe '#post_badge_tag' do
    context '未達成の場合' do
      it '空の星SVGを返す' do
        post = create(:post, user: user)
        html = helper.post_badge_tag(post)
        expect(html).to include('<svg')
        expect(html).to include('fill="none"')
        expect(html).to include('text-gray-400')
      end
    end

    context '達成済みの場合' do
      it '塗りつぶし星SVGを返す' do
        post = create(:post, user: user, achieved_at: Time.current)
        html = helper.post_badge_tag(post)
        expect(html).to include('<svg')
        expect(html).to include('fill="currentColor"')
        expect(html).to include('text-yellow-500')
      end
    end

    it 'class オプションが反映される' do
      post = create(:post, user: user)
      html = helper.post_badge_tag(post, class: 'custom-class')
      expect(html).to include('custom-class')
    end
  end
end
