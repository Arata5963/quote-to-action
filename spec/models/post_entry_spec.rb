# spec/models/post_entry_spec.rb
require 'rails_helper'

RSpec.describe PostEntry, type: :model do
  describe 'associations' do
    it { should belong_to(:post) }
    it { should belong_to(:user) }
  end

  describe 'validations' do
    context 'entry_type' do
      it { should validate_presence_of(:entry_type) }
    end

    context 'when entry_type is key_point' do
      subject { build(:post_entry, :key_point) }
      it { should validate_presence_of(:content) }
    end

    context 'when entry_type is quote' do
      subject { build(:post_entry, :quote) }
      it { should validate_presence_of(:content) }
    end

    context 'when entry_type is action' do
      subject { build(:post_entry, :action) }
      it { should validate_presence_of(:content) }
      it { should validate_presence_of(:deadline) }
    end

    context 'satisfaction_rating' do
      it 'allows nil' do
        entry = build(:post_entry, satisfaction_rating: nil)
        expect(entry).to be_valid
      end

      it 'allows values 1-5' do
        (1..5).each do |rating|
          entry = build(:post_entry, satisfaction_rating: rating)
          expect(entry).to be_valid
        end
      end

      it 'rejects values outside 1-5' do
        entry = build(:post_entry, satisfaction_rating: 0)
        expect(entry).not_to be_valid

        entry = build(:post_entry, satisfaction_rating: 6)
        expect(entry).not_to be_valid
      end
    end

    context 'uniqueness of entry_type per user and post' do
      let(:user) { create(:user) }
      let(:post) { create(:post) }

      it 'allows same entry_type for different users on same post' do
        create(:post_entry, :action, post: post, user: user)
        other_user = create(:user)
        entry = build(:post_entry, :action, post: post, user: other_user)
        expect(entry).to be_valid
      end

      it 'allows same entry_type for same user on different posts' do
        create(:post_entry, :action, post: post, user: user)
        other_post = create(:post)
        entry = build(:post_entry, :action, post: other_post, user: user)
        expect(entry).to be_valid
      end

      it 'rejects duplicate entry_type for same user on same post' do
        create(:post_entry, :action, post: post, user: user)
        entry = build(:post_entry, :action, post: post, user: user)
        expect(entry).not_to be_valid
        expect(entry.errors[:entry_type]).to include("この種類のエントリーは既に投稿済みです")
      end

      it 'allows different entry_types for same user on same post' do
        create(:post_entry, :action, post: post, user: user)
        entry = build(:post_entry, :key_point, post: post, user: user)
        expect(entry).to be_valid
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

    describe '.with_satisfaction' do
      it 'returns entries with satisfaction_rating' do
        entry_with = create(:post_entry, :with_satisfaction)
        entry_without = create(:post_entry, satisfaction_rating: nil)

        expect(PostEntry.with_satisfaction).to include(entry_with)
        expect(PostEntry.with_satisfaction).not_to include(entry_without)
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
    it 'sets achieved_at for action entries' do
      entry = create(:post_entry, :action)
      expect { entry.achieve! }.to change { entry.achieved_at }.from(nil)
    end

    it 'does not set achieved_at for key_point entries' do
      entry = create(:post_entry, :key_point)
      entry.achieve!
      expect(entry.achieved_at).to be_nil
    end

    it 'toggles already achieved entries to not achieved' do
      entry = create(:post_entry, :action, :achieved)
      expect(entry.achieved_at).to be_present
      entry.achieve!
      expect(entry.achieved_at).to be_nil
    end
  end

  describe '#satisfaction_label' do
    it 'returns the label for the rating' do
      entry = build(:post_entry, satisfaction_rating: 5)
      expect(entry.satisfaction_label).to eq("とても満足")
    end

    it 'returns nil when rating is nil' do
      entry = build(:post_entry, satisfaction_rating: nil)
      expect(entry.satisfaction_label).to be_nil
    end
  end

  describe '#satisfaction_stars' do
    it 'returns star representation for rating 5' do
      entry = build(:post_entry, satisfaction_rating: 5)
      expect(entry.satisfaction_stars).to eq("★★★★★")
    end

    it 'returns star representation for rating 3' do
      entry = build(:post_entry, satisfaction_rating: 3)
      expect(entry.satisfaction_stars).to eq("★★★☆☆")
    end

    it 'returns star representation for rating 1' do
      entry = build(:post_entry, satisfaction_rating: 1)
      expect(entry.satisfaction_stars).to eq("★☆☆☆☆")
    end

    it 'returns nil when rating is nil' do
      entry = build(:post_entry, satisfaction_rating: nil)
      expect(entry.satisfaction_stars).to be_nil
    end
  end

  describe 'anonymous feature' do
    describe '#anonymous?' do
      it 'returns true when anonymous is true' do
        entry = build(:post_entry, :anonymous)
        expect(entry.anonymous?).to be true
      end

      it 'returns false when anonymous is false' do
        entry = build(:post_entry, anonymous: false)
        expect(entry.anonymous?).to be false
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
