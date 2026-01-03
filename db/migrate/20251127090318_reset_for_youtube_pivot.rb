# frozen_string_literal: true

# YouTube特化へのピボットに伴う既存データリセット
class ResetForYoutubePivot < ActiveRecord::Migration[7.2]
  def up
    # 既存データを全削除（破壊的変更）
    # SQLで直接削除（モデル名変更に依存しない）
    execute "DELETE FROM achievements" if table_exists?(:achievements)
    execute "DELETE FROM likes" if table_exists?(:likes)
    execute "DELETE FROM comments" if table_exists?(:comments)
    execute "DELETE FROM posts" if table_exists?(:posts)
    execute "DELETE FROM user_badges" if table_exists?(:user_badges)

    # ユーザーアカウントは残す（認証情報を保持）
  end

  def down
    # データは復元不可
    raise ActiveRecord::IrreversibleMigration, "既存データの削除は取り消せません"
  end
end
