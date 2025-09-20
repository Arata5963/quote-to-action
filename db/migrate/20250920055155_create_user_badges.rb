# db/migrate/xxxx_create_user_badges.rb
class CreateUserBadges < ActiveRecord::Migration[7.2]
  def change
    create_table :user_badges do |t|
      t.references :user, null: false, foreign_key: true
      t.string :badge_key, null: false
      t.datetime :awarded_at, null: false, default: -> { "CURRENT_TIMESTAMP" }
      t.timestamps
    end
    
    # 同じバッジは1回のみ獲得可能
    add_index :user_badges, [:user_id, :badge_key], unique: true
  end
end