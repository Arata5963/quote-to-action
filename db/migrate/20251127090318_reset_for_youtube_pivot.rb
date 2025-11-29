# frozen_string_literal: true

# YouTube特化へのピボットに伴う既存データリセット
class ResetForYoutubePivot < ActiveRecord::Migration[7.2]
  def up
    # 既存データを全削除（破壊的変更）
    # 関連テーブルから順に削除（外部キー制約のため）
    Achievement.delete_all
    Like.delete_all
    Comment.delete_all
    Post.delete_all
    UserBadge.delete_all

    # ユーザーアカウントは残す（認証情報を保持）
  end

  def down
    # データは復元不可
    raise ActiveRecord::IrreversibleMigration, "既存データの削除は取り消せません"
  end
end
