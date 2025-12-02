require 'rails_helper'

RSpec.describe User, type: :model do
  describe "validations" do
    subject { create(:user) }
    it { should validate_presence_of(:email) }
    it { should validate_uniqueness_of(:email).case_insensitive }
  end

  describe "associations" do
    it { should have_many(:posts).dependent(:destroy) }
    it { should have_many(:achievements).dependent(:destroy) }
    it { should have_many(:user_badges).dependent(:destroy) }
    it { should have_many(:comments).dependent(:destroy) }
    it { should have_many(:likes).dependent(:destroy) }
  end

  describe "#available_badges_count" do
    let(:user) { create(:user) }

    it "初期値は BADGE_POOL.size と等しい" do
      expect(user.available_badges_count).to eq(BADGE_POOL.size)
    end

    it "獲得が増えると残数が減る" do
      user.user_badges.create!(
        badge_key: BADGE_POOL.first[:key],
        awarded_at: Time.current
      )
      expect(user.available_badges_count).to eq(BADGE_POOL.size - 1)
    end
  end

  describe "dependent destroy (実データ確認)" do
    it "ユーザー削除で関連レコードも削除される" do
      user = create(:user)
      post = create(:post, user: user)
      create(:achievement, user: user, post: post, achieved_at: Date.current)
      # ▼ Factoryなしで関連経由で作成
      user.user_badges.create!(badge_key: BADGE_POOL.first[:key], awarded_at: Time.current)
      create(:comment, user: user, post: post)
      create(:like, user: user, post: post)

      expect {
        user.destroy
      }.to change {
        [
          Post.where(user_id: user.id).count,
          Achievement.where(user_id: user.id).count,
          UserBadge.where(user_id: user.id).count,
          Comment.where(user_id: user.id).count,
          Like.where(user_id: user.id).count
        ]
      }.from([ 1, 1, 1, 1, 1 ]).to([ 0, 0, 0, 0, 0 ])
    end
  end
  describe '.from_omniauth' do
    let(:auth) do
      OmniAuth::AuthHash.new(
        provider: 'google_oauth2',
        uid: '123456789',
        info: {
          email: 'test@example.com'
        }
      )
    end

    context 'すでに連携済みのユーザーの場合' do
      let!(:existing_user) do
        create(:user,
              email: 'test@example.com',
              provider: 'google_oauth2',
              uid: '123456789')
      end

      it '既存ユーザーを返す' do
        result = User.from_omniauth(auth)
        expect(result).to eq(existing_user)
      end

      it 'ユーザー数が増えない' do
        expect {
          User.from_omniauth(auth)
        }.not_to change(User, :count)
      end
    end

    context '同じメールの既存ユーザーがいる場合' do
      let!(:existing_user) do
        create(:user, email: 'test@example.com')
      end

      it '既存ユーザーにproviderとuidを追加する' do
        result = User.from_omniauth(auth)
        expect(result.provider).to eq('google_oauth2')
        expect(result.uid).to eq('123456789')
      end

      it 'ユーザー数が増えない' do
        expect {
          User.from_omniauth(auth)
        }.not_to change(User, :count)
      end
    end

    context '新規ユーザーの場合' do
      it '新しいユーザーを作成する' do
        expect {
          User.from_omniauth(auth)
        }.to change(User, :count).by(1)
      end

      it '正しい属性でユーザーが作成される' do
        user = User.from_omniauth(auth)
        expect(user.email).to eq('test@example.com')
        expect(user.provider).to eq('google_oauth2')
        expect(user.uid).to eq('123456789')
        expect(user.password).to be_present
      end

      it 'パスワードが自動生成される' do
        user = User.from_omniauth(auth)
        expect(user.encrypted_password).to be_present
      end
    end
  end
end
