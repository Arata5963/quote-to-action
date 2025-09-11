class DeviseCreateUsers < ActiveRecord::Migration[7.2]
  def change
    create_table :users do |t|
      # ユーザーのメールアドレス（必須・重複不可）
      t.string :email, null: false, default: ""

      # 暗号化済みのパスワード（生パスワードは保存されない）
      t.string :encrypted_password, null: false, default: ""

      # パスワードリセット用のトークン
      t.string :reset_password_token

      # パスワードリセット要求を送信した時刻
      t.datetime :reset_password_sent_at

      # 「ログイン状態を保持する」チェック用
      t.datetime :remember_created_at

      # レコード作成日時・更新日時（自動管理）
      t.timestamps null: false
    end

    # メールアドレスは一意制約を設定（同じアドレスでは登録不可）
    add_index :users, :email, unique: true

    # パスワードリセット用トークンも一意制約を設定
    add_index :users, :reset_password_token, unique: true
  end
end
