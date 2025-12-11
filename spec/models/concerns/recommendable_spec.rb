# spec/models/concerns/recommendable_spec.rb
require "rails_helper"

RSpec.describe Recommendable, type: :model do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }

  describe "#recommended_posts" do
    context "同じカテゴリの投稿が十分にある場合" do
      let!(:post) { create(:post, user: user, category: :education) }
      let!(:same_category_posts) do
        create_list(:post, 5, user: other_user, category: :education)
      end

      it "同じカテゴリから3件取得する" do
        recommendations = post.recommended_posts(limit: 3)

        expect(recommendations.size).to eq 3
        expect(recommendations).to all(have_attributes(category: "education"))
      end

      it "自分の投稿を除外する" do
        recommendations = post.recommended_posts(limit: 3)

        expect(recommendations).not_to include(post)
        expect(recommendations.map(&:user_id)).not_to include(user.id)
      end

      it "達成した投稿自体を除外する" do
        recommendations = post.recommended_posts(limit: 3)

        expect(recommendations).not_to include(post)
      end
    end

    context "同じカテゴリの投稿が不足している場合" do
      let!(:post) { create(:post, user: user, category: :education) }
      let!(:same_category_post) { create(:post, user: other_user, category: :education) }
      let!(:other_category_posts) do
        create_list(:post, 5, user: other_user, category: :music)
      end

      it "他カテゴリから補填して3件取得する" do
        recommendations = post.recommended_posts(limit: 3)

        expect(recommendations.size).to eq 3
        expect(recommendations).to include(same_category_post)
      end

      it "自分の投稿を除外する" do
        # 自分の別カテゴリ投稿を追加
        create(:post, user: user, category: :music)

        recommendations = post.recommended_posts(limit: 3)

        expect(recommendations.map(&:user_id)).not_to include(user.id)
      end
    end

    context "推薦できる投稿が0件の場合" do
      let!(:post) { create(:post, user: user, category: :education) }

      it "空の配列を返す" do
        recommendations = post.recommended_posts(limit: 3)

        expect(recommendations).to eq []
      end
    end

    context "推薦できる投稿が1〜2件の場合" do
      let!(:post) { create(:post, user: user, category: :education) }
      let!(:other_posts) { create_list(:post, 2, user: other_user) }

      it "取得できた分だけ返す" do
        recommendations = post.recommended_posts(limit: 3)

        expect(recommendations.size).to eq 2
      end
    end

    context "limitが0以下の場合" do
      let!(:post) { create(:post, user: user, category: :education) }
      let!(:other_posts) { create_list(:post, 3, user: other_user) }

      it "空のリレーションを返す" do
        recommendations = post.recommended_posts(limit: 0)

        expect(recommendations).to be_empty
      end
    end

    context "ランダム性の確認" do
      let!(:post) { create(:post, user: user, category: :education) }
      let!(:same_category_posts) do
        create_list(:post, 10, user: other_user, category: :education)
      end

      it "複数回実行すると異なる結果を返す可能性がある" do
        results = 10.times.map { post.recommended_posts(limit: 3).pluck(:id).sort }
        unique_results = results.uniq

        # 完全に同じ結果が10回続く確率は非常に低い
        expect(unique_results.size).to be > 1
      end
    end
  end
end
