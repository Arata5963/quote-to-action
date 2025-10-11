class CreateLikes < ActiveRecord::Migration[7.2]
  def change
    create_table :likes do |t|
      # 外部キー: ユーザー
      t.references :user, null: false, foreign_key: true

      # 外部キー: 投稿
      t.references :post, null: false, foreign_key: true

      # タイムスタンプ
      t.timestamps
    end

    # 同じユーザーが同じ投稿に複数回いいねできないようにする
    add_index :likes, [ :user_id, :post_id ], unique: true
  end
end
