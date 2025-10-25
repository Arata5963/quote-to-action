require 'rails_helper'

RSpec.describe Achievement, type: :model do
  describe "validations" do
    subject { create(:achievement) }

    it do
      should validate_uniqueness_of(:post_id)
        .scoped_to(:user_id, :awarded_at)
        .with_message("今日はすでに達成済みです")
    end
  end

  describe "associations" do
    it { should belong_to(:user) }
    it { should belong_to(:post) }
  end
end
