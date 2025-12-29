# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.2].define(version: 2025_12_29_040707) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "achievements", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "post_id", null: false
    t.date "achieved_at", default: -> { "CURRENT_DATE" }, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["post_id"], name: "index_achievements_on_post_id"
    t.index ["user_id", "post_id"], name: "idx_unique_achievements", unique: true
    t.index ["user_id"], name: "index_achievements_on_user_id"
  end

  create_table "cheers", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "post_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["post_id"], name: "index_cheers_on_post_id"
    t.index ["user_id", "post_id"], name: "index_cheers_on_user_id_and_post_id", unique: true
    t.index ["user_id"], name: "index_cheers_on_user_id"
  end

  create_table "comments", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "post_id", null: false
    t.string "content", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["post_id", "created_at"], name: "index_comments_on_post_id_and_created_at"
    t.index ["post_id"], name: "index_comments_on_post_id"
    t.index ["user_id"], name: "index_comments_on_user_id"
  end

  create_table "favorite_videos", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "youtube_url", null: false
    t.string "youtube_title"
    t.string "youtube_channel_name"
    t.integer "position", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "position"], name: "index_favorite_videos_on_user_id_and_position", unique: true
    t.index ["user_id"], name: "index_favorite_videos_on_user_id"
  end

  create_table "posts", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.text "action_plan"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "youtube_url", null: false
    t.datetime "achieved_at"
    t.string "youtube_title"
    t.string "youtube_channel_name"
    t.date "deadline"
    t.index ["deadline"], name: "index_posts_on_deadline"
    t.index ["user_id"], name: "index_posts_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "avatar"
    t.string "provider"
    t.string "uid"
    t.string "name"
    t.string "favorite_quote", limit: 50
    t.string "favorite_quote_url"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "achievements", "posts"
  add_foreign_key "achievements", "users"
  add_foreign_key "cheers", "posts"
  add_foreign_key "cheers", "users"
  add_foreign_key "comments", "posts"
  add_foreign_key "comments", "users"
  add_foreign_key "favorite_videos", "users"
  add_foreign_key "posts", "users"
end
