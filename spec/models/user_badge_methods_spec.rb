# spec/models/user_badge_methods_spec.rb
require 'rails_helper'

RSpec.describe UserBadge, type: :model do
  let(:user) { create(:user) }

  describe '#badge_info' do
    context '有効なバッジキーの場合' do
      it 'BADGE_POOLからバッジ情報を取得できる' do
        badge_key = BADGE_POOL.first[:key]
        user_badge = user.user_badges.create!(badge_key: badge_key, awarded_at: Time.current)

        expect(user_badge.badge_info).to be_a(Hash)
        expect(user_badge.badge_info[:key]).to eq(badge_key)
      end

      it 'バッジ情報にname、description、svgが含まれる' do
        badge_key = BADGE_POOL.first[:key]
        user_badge = user.user_badges.create!(badge_key: badge_key, awarded_at: Time.current)

        badge_info = user_badge.badge_info
        expect(badge_info).to have_key(:name)
        expect(badge_info).to have_key(:description)
        expect(badge_info).to have_key(:svg)
      end
    end

    context '無効なバッジキーの場合' do
      it 'nilを返す' do
        user_badge = user.user_badges.new(badge_key: 'invalid_key', awarded_at: Time.current)
        user_badge.save(validate: false) # バリデーションをスキップして保存

        expect(user_badge.badge_info).to be_nil
      end
    end
  end

  describe '#badge_name' do
    context '有効なバッジキーの場合' do
      it 'バッジ名を返す' do
        badge_key = BADGE_POOL.first[:key]
        user_badge = user.user_badges.create!(badge_key: badge_key, awarded_at: Time.current)

        expect(user_badge.badge_name).to eq(BADGE_POOL.first[:name])
        expect(user_badge.badge_name).to be_a(String)
        expect(user_badge.badge_name.length).to be > 0
      end

      it 'すべてのBADGE_POOLのバッジ名を正しく返す' do
        BADGE_POOL.each do |badge_data|
          user_badge = user.user_badges.create!(badge_key: badge_data[:key], awarded_at: Time.current)
          expect(user_badge.badge_name).to eq(badge_data[:name])
          user_badge.destroy # 次のループのために削除
        end
      end
    end

    context '無効なバッジキーの場合' do
      it 'デフォルトメッセージを返す' do
        user_badge = user.user_badges.new(badge_key: 'invalid_key', awarded_at: Time.current)
        user_badge.save(validate: false)

        expect(user_badge.badge_name).to eq("不明なバッジ")
      end
    end
  end

  describe '#badge_svg' do
    context '有効なバッジキーの場合' do
      it 'SVGコードを返す' do
        badge_key = BADGE_POOL.first[:key]
        user_badge = user.user_badges.create!(badge_key: badge_key, awarded_at: Time.current)

        expect(user_badge.badge_svg).to be_a(String)
        expect(user_badge.badge_svg).to include('<svg')
      end

      it 'すべてのBADGE_POOLのSVGを正しく返す' do
        BADGE_POOL.each do |badge_data|
          user_badge = user.user_badges.create!(badge_key: badge_data[:key], awarded_at: Time.current)
          expect(user_badge.badge_svg).to eq(badge_data[:svg])
          expect(user_badge.badge_svg).to include('<svg')
          user_badge.destroy
        end
      end
    end

    context '無効なバッジキーの場合' do
      it '空文字列を返す' do
        user_badge = user.user_badges.new(badge_key: 'invalid_key', awarded_at: Time.current)
        user_badge.save(validate: false)

        expect(user_badge.badge_svg).to eq("")
      end
    end
  end

  describe '#description' do
    context '有効なバッジキーの場合' do
      it 'バッジの説明を返す' do
        badge_key = BADGE_POOL.first[:key]
        user_badge = user.user_badges.create!(badge_key: badge_key, awarded_at: Time.current)

        expect(user_badge.description).to eq(BADGE_POOL.first[:description])
        expect(user_badge.description).to be_a(String)
        expect(user_badge.description.length).to be > 0
      end

      it 'すべてのBADGE_POOLの説明を正しく返す' do
        BADGE_POOL.each do |badge_data|
          user_badge = user.user_badges.create!(badge_key: badge_data[:key], awarded_at: Time.current)
          expect(user_badge.description).to eq(badge_data[:description])
          user_badge.destroy
        end
      end
    end

    context '無効なバッジキーの場合' do
      it '空文字列を返す' do
        user_badge = user.user_badges.new(badge_key: 'invalid_key', awarded_at: Time.current)
        user_badge.save(validate: false)

        expect(user_badge.description).to eq("")
      end
    end
  end

  describe 'associations' do
    it { should belong_to(:user) }
  end

  describe 'validations' do
    subject { user.user_badges.create!(badge_key: BADGE_POOL.first[:key], awarded_at: Time.current) }

    it { should validate_presence_of(:badge_key) }

    it 'ユーザーごとにバッジキーがユニークである' do
      should validate_uniqueness_of(:badge_key).scoped_to(:user_id)
    end
  end

  describe 'scope :recent' do
    before do
      # 異なる日時でバッジを作成
      @old_badge = user.user_badges.create!(
        badge_key: BADGE_POOL[0][:key],
        awarded_at: 3.days.ago
      )
      @middle_badge = user.user_badges.create!(
        badge_key: BADGE_POOL[1][:key],
        awarded_at: 1.day.ago
      )
      @new_badge = user.user_badges.create!(
        badge_key: BADGE_POOL[2][:key],
        awarded_at: Time.current
      )
    end

    it '新しい順に並ぶ' do
      expect(user.user_badges.recent).to eq([ @new_badge, @middle_badge, @old_badge ])
    end
  end
end
