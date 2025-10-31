# spec/models/application_record_spec.rb
require 'rails_helper'

RSpec.describe ApplicationRecord, type: :model do
  describe '基本設定' do
    it 'ApplicationRecordは抽象クラスである' do
      expect(ApplicationRecord.abstract_class?).to be true
    end

    it 'ApplicationRecordを継承したモデルが作成できる' do
      # テスト用のモデルクラスを動的に作成
      test_model = Class.new(ApplicationRecord) do
        self.table_name = 'users'
      end

      expect(test_model.superclass).to eq(ApplicationRecord)
    end
  end

  describe '継承関係' do
    it 'ActiveRecord::Baseを継承している' do
      expect(ApplicationRecord.superclass).to eq(ActiveRecord::Base)
    end

    it '既存モデルがApplicationRecordを継承している' do
      expect(User.superclass).to eq(ApplicationRecord)
      expect(Post.superclass).to eq(ApplicationRecord)
      expect(Achievement.superclass).to eq(ApplicationRecord)
    end
  end
end