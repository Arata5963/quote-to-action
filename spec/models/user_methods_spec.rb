# spec/models/user_methods_spec.rb
require 'rails_helper'

RSpec.describe User, type: :model do
  describe '#total_achievements_count' do
    let(:user) { create(:user) }
    let(:post1) { create(:post, user: user) }
    let(:post2) { create(:post, user: user) }

    context '達成記録がない場合' do
      it '0を返す' do
        expect(user.total_achievements_count).to eq(0)
      end
    end

    context '達成記録がある場合' do
      before do
        create(:achievement, user: user, post: post1, awarded_at: Date.current)
        create(:achievement, user: user, post: post1, awarded_at: Date.current - 1.day)
        create(:achievement, user: user, post: post2, awarded_at: Date.current - 2.days)
      end

      it '達成記録の合計数を返す' do
        expect(user.total_achievements_count).to eq(3)
      end
    end

    context '複数ユーザーの達成記録がある場合' do
      let(:other_user) { create(:user) }
      let(:other_post) { create(:post, user: other_user) }

      before do
        # 対象ユーザーの達成記録
        create(:achievement, user: user, post: post1, awarded_at: Date.current)

        # 他のユーザーの達成記録（カウントされない）
        create(:achievement, user: other_user, post: other_post, awarded_at: Date.current)
      end

      it '自分の達成記録のみカウントする' do
        expect(user.total_achievements_count).to eq(1)
        expect(other_user.total_achievements_count).to eq(1)
      end
    end
  end

  describe 'avatar (CarrierWave)' do
    let(:user) { create(:user) }

    context 'アバター画像がアップロードされていない場合' do
      it 'avatarはnilまたは空である' do
        expect(user.avatar.present?).to be_falsy
      end
    end

    context 'アバター画像がアップロードされている場合' do
      let(:user_with_avatar) { create(:user, :with_avatar) }

      it 'avatarが存在する' do
        expect(user_with_avatar.avatar.present?).to be true
      end

      it 'avatarのURLが生成される' do
        expect(user_with_avatar.avatar.url).to be_present
      end

      it 'サムネイルURLが生成される' do
        expect(user_with_avatar.avatar.thumb.url).to be_present
      end
    end
  end

  describe 'password validation (Devise)' do
    context '新規ユーザー作成時' do
      it 'パスワードが短すぎる場合はエラー' do
        user = build(:user, password: '12345', password_confirmation: '12345')
        expect(user).not_to be_valid
        expect(user.errors[:password]).to be_present
      end

      it 'パスワードが十分な長さの場合は有効' do
        user = build(:user, password: '123456', password_confirmation: '123456')
        expect(user).to be_valid
      end

      it 'パスワード確認が一致しない場合はエラー' do
        user = build(:user, password: '123456', password_confirmation: 'different')
        expect(user).not_to be_valid
        expect(user.errors[:password_confirmation]).to be_present
      end
    end
  end
end
