# spec/system/achievement_recommendations_spec.rb
require "rails_helper"

RSpec.describe "AchievementRecommendations", type: :system do
  # JavaScriptを使用するため、Capybara + Seleniumなどのヘッドレスブラウザを使用
  # 基本テストはrack_testでTurbo Stream非対応のため、JS統合テストは限定的
  before do
    driven_by(:rack_test)
  end

  let(:user) { create(:user) }
  let(:other_user) { create(:user) }

  describe "達成後のレコメンドモーダル" do
    context "推薦投稿がある場合" do
      let!(:my_post) { create(:post, user: user, category: :education) }
      let!(:recommended_posts) do
        create_list(:post, 3, user: other_user, category: :education)
      end

      before do
        sign_in user
      end

      it "達成ボタンをクリックすると達成状態に変わる" do
        visit post_path(my_post)

        # 達成前: みただけ？ボタンが表示
        expect(page).to have_button "みただけ？"

        # 達成ボタンをクリック
        click_button "みただけ？"

        # 達成後: やったけど？が表示（リダイレクト時）
        expect(page).to have_content "やったけど？"
        expect(my_post.reload).to be_achieved
      end
    end

    context "推薦投稿がない場合" do
      let!(:my_post) { create(:post, user: user, category: :education) }

      before do
        sign_in user
      end

      it "達成処理は正常に完了する" do
        visit post_path(my_post)

        click_button "みただけ？"

        expect(my_post.reload).to be_achieved
      end
    end
  end

  describe "レコメンドモーダルの表示内容" do
    # Turbo Streamのモーダル表示はJavaScript統合テストで確認
    # ここではビューのレンダリングテストを行う

    let(:post_record) { create(:post, user: user, category: :education) }
    let!(:recommended_posts) do
      create_list(:post, 3, user: other_user, category: :education,
                  youtube_title: "おすすめ動画",
                  youtube_channel_name: "テストチャンネル")
    end

    before do
      sign_in user
    end

    it "推薦投稿の情報が取得できる" do
      recommendations = post_record.recommended_posts(limit: 3)

      expect(recommendations.size).to eq 3
      expect(recommendations.first.youtube_title).to eq "おすすめ動画"
      expect(recommendations.first.youtube_channel_name).to eq "テストチャンネル"
    end
  end
end
