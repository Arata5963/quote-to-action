require 'rails_helper'

RSpec.describe User, type: :model do
  describe "validations" do
    subject { create(:user) }
    it { should validate_presence_of(:email) }
    it { should validate_uniqueness_of(:email).case_insensitive }
  end
  describe "associations" do
    it { should have_many(:posts) }
    it { should have_many(:achievements) }
    it { should have_many(:comments) }
    it { should have_many(:likes) }
  end
end