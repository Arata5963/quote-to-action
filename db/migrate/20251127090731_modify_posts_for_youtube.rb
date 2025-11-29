# frozen_string_literal: true

# Postテーブルをyoutube特化に変更
class ModifyPostsForYoutube < ActiveRecord::Migration[7.2]
  def change
    # カラム名変更: related_url → youtube_url
    rename_column :posts, :related_url, :youtube_url

    # NOT NULL制約追加（YouTube URLは必須）
    change_column_null :posts, :youtube_url, false

    # 達成日時カラム追加（タスク型達成管理）
    add_column :posts, :achieved_at, :datetime, null: true

    # imageカラム削除（YouTubeサムネイル自動取得のため不要）
    remove_column :posts, :image, :string
  end
end
