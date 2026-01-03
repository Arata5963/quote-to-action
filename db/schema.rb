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

ActiveRecord::Schema[7.2].define(version: 2026_01_03_014433) do
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

  create_table "notifications", force: :cascade do |t|
    t.string "target_type", null: false
    t.bigint "target_id", null: false
    t.string "notifiable_type", null: false
    t.bigint "notifiable_id", null: false
    t.string "key", null: false
    t.string "group_type"
    t.bigint "group_id"
    t.integer "group_owner_id"
    t.string "notifier_type"
    t.bigint "notifier_id"
    t.text "parameters"
    t.datetime "opened_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["group_owner_id"], name: "index_notifications_on_group_owner_id"
    t.index ["group_type", "group_id"], name: "index_notifications_on_group"
    t.index ["notifiable_type", "notifiable_id"], name: "index_notifications_on_notifiable"
    t.index ["notifier_type", "notifier_id"], name: "index_notifications_on_notifier"
    t.index ["target_type", "target_id"], name: "index_notifications_on_target"
  end

  create_table "post_comparisons", force: :cascade do |t|
    t.bigint "source_post_id", null: false
    t.bigint "target_post_id", null: false
    t.text "reason"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["source_post_id", "target_post_id"], name: "index_post_comparisons_on_source_post_id_and_target_post_id", unique: true
    t.index ["source_post_id"], name: "index_post_comparisons_on_source_post_id"
    t.index ["target_post_id"], name: "index_post_comparisons_on_target_post_id"
  end

  create_table "post_entries", force: :cascade do |t|
    t.bigint "post_id", null: false
    t.integer "entry_type", default: 0, null: false
    t.text "content"
    t.date "deadline"
    t.datetime "achieved_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "satisfaction_rating"
    t.string "title"
    t.datetime "published_at"
    t.integer "recommendation_level"
    t.text "target_audience"
    t.text "recommendation_point"
    t.index ["post_id", "created_at"], name: "index_post_entries_on_post_id_and_created_at"
    t.index ["post_id"], name: "index_post_entries_on_post_id"
    t.check_constraint "satisfaction_rating IS NULL OR satisfaction_rating >= 1 AND satisfaction_rating <= 5", name: "satisfaction_rating_range"
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
    t.string "youtube_video_id"
    t.string "youtube_channel_thumbnail_url"
    t.index ["deadline"], name: "index_posts_on_deadline"
    t.index ["user_id", "youtube_video_id"], name: "index_posts_on_user_id_and_youtube_video_id", unique: true
    t.index ["user_id"], name: "index_posts_on_user_id"
  end

  create_table "recommendation_clicks", force: :cascade do |t|
    t.bigint "post_id", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["post_id", "user_id"], name: "index_recommendation_clicks_on_post_id_and_user_id", unique: true
    t.index ["post_id"], name: "index_recommendation_clicks_on_post_id"
    t.index ["user_id"], name: "index_recommendation_clicks_on_user_id"
  end

  create_table "subscriptions", force: :cascade do |t|
    t.string "target_type", null: false
    t.bigint "target_id", null: false
    t.string "key", null: false
    t.boolean "subscribing", default: true, null: false
    t.boolean "subscribing_to_email", default: true, null: false
    t.datetime "subscribed_at"
    t.datetime "unsubscribed_at"
    t.datetime "subscribed_to_email_at"
    t.datetime "unsubscribed_to_email_at"
    t.text "optional_targets"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_subscriptions_on_key"
    t.index ["target_type", "target_id", "key"], name: "index_subscriptions_on_target_type_and_target_id_and_key", unique: true
    t.index ["target_type", "target_id"], name: "index_subscriptions_on_target"
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
  add_foreign_key "post_comparisons", "posts", column: "source_post_id"
  add_foreign_key "post_comparisons", "posts", column: "target_post_id"
  add_foreign_key "post_entries", "posts"
  add_foreign_key "posts", "users"
  add_foreign_key "recommendation_clicks", "posts"
  add_foreign_key "recommendation_clicks", "users"
end
