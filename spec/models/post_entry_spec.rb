# spec/models/post_entry_spec.rb
require 'rails_helper'

RSpec.describe PostEntry, type: :model do
  describe 'associations' do
    it { should belong_to(:post) }
    it { should belong_to(:user) }
  end

  describe 'validations' do
    it { should validate_presence_of(:content) }

    context 'uniqueness of user_id per post' do
      let(:user) { create(:user) }
      let(:post) { create(:post) }

      it 'allows same user on different posts' do
        create(:post_entry, post: post, user: user)
        other_post = create(:post)
        entry = build(:post_entry, post: other_post, user: user)
        expect(entry).to be_valid
      end

      it 'allows different users on same post' do
        create(:post_entry, post: post, user: user)
        other_user = create(:user)
        entry = build(:post_entry, post: post, user: other_user)
        expect(entry).to be_valid
      end

      it 'rejects duplicate user on same post' do
        create(:post_entry, post: post, user: user)
        entry = build(:post_entry, post: post, user: user)
        expect(entry).not_to be_valid
        expect(entry.errors[:user_id]).to include("この動画にはすでにアクションプランを投稿しています")
      end
    end
  end

  describe 'scopes' do
    describe '.recent' do
      it 'returns entries in descending order of created_at' do
        old_entry = create(:post_entry)
        new_entry = create(:post_entry)

        expect(PostEntry.recent.first).to eq(new_entry)
      end
    end

    describe '.not_achieved' do
      it 'returns entries without achieved_at' do
        not_achieved = create(:post_entry)
        achieved = create(:post_entry, :achieved)

        expect(PostEntry.not_achieved).to include(not_achieved)
        expect(PostEntry.not_achieved).not_to include(achieved)
      end
    end

    describe '.achieved' do
      it 'returns entries with achieved_at' do
        not_achieved = create(:post_entry)
        achieved = create(:post_entry, :achieved)

        expect(PostEntry.achieved).to include(achieved)
        expect(PostEntry.achieved).not_to include(not_achieved)
      end
    end
  end

  describe '#achieved?' do
    it 'returns true when achieved_at is present' do
      entry = build(:post_entry, :achieved)
      expect(entry.achieved?).to be true
    end

    it 'returns false when achieved_at is nil' do
      entry = build(:post_entry)
      expect(entry.achieved?).to be false
    end
  end

  describe '#achieve!' do
    it 'sets achieved_at when not achieved' do
      entry = create(:post_entry)
      expect { entry.achieve! }.to change { entry.achieved_at }.from(nil)
    end

    it 'clears achieved_at when already achieved' do
      entry = create(:post_entry, :achieved)
      expect(entry.achieved_at).to be_present
      entry.achieve!
      expect(entry.achieved_at).to be_nil
    end
  end

  describe 'anonymous feature' do
    describe '#display_anonymous?' do
      it 'returns true when anonymous is true' do
        entry = build(:post_entry, :anonymous)
        expect(entry.display_anonymous?).to be true
      end

      it 'returns false when anonymous is false' do
        entry = build(:post_entry, anonymous: false)
        expect(entry.display_anonymous?).to be false
      end
    end

    describe '#display_user_name' do
      let(:user) { create(:user, name: 'テストユーザー') }

      it 'returns 匿名 when anonymous is true' do
        entry = build(:post_entry, :anonymous, user: user)
        expect(entry.display_user_name).to eq('匿名')
      end

      it 'returns user name when anonymous is false' do
        entry = build(:post_entry, anonymous: false, user: user)
        expect(entry.display_user_name).to eq('テストユーザー')
      end
    end

    describe '#display_avatar' do
      let(:user) { create(:user) }

      it 'returns nil when anonymous is true' do
        entry = build(:post_entry, :anonymous, user: user)
        expect(entry.display_avatar).to be_nil
      end

      it 'returns user avatar when anonymous is false' do
        entry = build(:post_entry, anonymous: false, user: user)
        expect(entry.display_avatar).to eq(user.avatar)
      end
    end
  end
end
