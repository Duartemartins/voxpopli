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

ActiveRecord::Schema[8.0].define(version: 2025_12_08_172813) do
  create_table "api_keys", id: :string, force: :cascade do |t|
    t.string "user_id", null: false
    t.string "name", null: false
    t.string "key_digest", null: false
    t.string "key_prefix", null: false
    t.integer "requests_count", default: 0
    t.integer "rate_limit", default: 1000
    t.datetime "last_used_at"
    t.datetime "expires_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key_prefix"], name: "index_api_keys_on_key_prefix", unique: true
    t.index ["user_id"], name: "index_api_keys_on_user_id"
  end

  create_table "bookmarks", id: :string, force: :cascade do |t|
    t.string "user_id", null: false
    t.string "post_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["post_id"], name: "index_bookmarks_on_post_id"
    t.index ["user_id", "post_id"], name: "index_bookmarks_on_user_id_and_post_id", unique: true
    t.index ["user_id"], name: "index_bookmarks_on_user_id"
  end

  create_table "follows", id: :string, force: :cascade do |t|
    t.string "follower_id", null: false
    t.string "followed_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["followed_id"], name: "index_follows_on_followed_id"
    t.index ["follower_id", "followed_id"], name: "index_follows_on_follower_id_and_followed_id", unique: true
    t.index ["follower_id"], name: "index_follows_on_follower_id"
  end

  create_table "invites", id: :string, force: :cascade do |t|
    t.string "inviter_id"
    t.string "invitee_id"
    t.string "code", null: false
    t.string "email"
    t.datetime "used_at"
    t.datetime "expires_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_invites_on_code", unique: true
    t.index ["invitee_id"], name: "index_invites_on_invitee_id"
    t.index ["inviter_id"], name: "index_invites_on_inviter_id"
  end

  create_table "notifications", id: :string, force: :cascade do |t|
    t.string "user_id", null: false
    t.string "actor_id", null: false
    t.string "notifiable_type"
    t.string "notifiable_id"
    t.string "action", null: false
    t.boolean "read", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["actor_id"], name: "index_notifications_on_actor_id"
    t.index ["notifiable_type", "notifiable_id"], name: "index_notifications_on_notifiable_type_and_notifiable_id"
    t.index ["user_id", "read", "created_at"], name: "index_notifications_on_user_id_and_read_and_created_at"
    t.index ["user_id"], name: "index_notifications_on_user_id"
  end

  create_table "posts", id: :string, force: :cascade do |t|
    t.string "user_id", null: false
    t.string "theme_id"
    t.string "parent_id"
    t.string "repost_of_id"
    t.text "body", null: false
    t.integer "votes_count", default: 0
    t.integer "score", default: 0
    t.integer "replies_count", default: 0
    t.integer "reposts_count", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_posts_on_created_at"
    t.index ["parent_id"], name: "index_posts_on_parent_id"
    t.index ["repost_of_id"], name: "index_posts_on_repost_of_id"
    t.index ["score", "created_at"], name: "index_posts_on_score_and_created_at"
    t.index ["theme_id", "created_at"], name: "index_posts_on_theme_id_and_created_at"
    t.index ["theme_id"], name: "index_posts_on_theme_id"
    t.index ["user_id", "created_at"], name: "index_posts_on_user_id_and_created_at"
    t.index ["user_id"], name: "index_posts_on_user_id"
  end

  create_table "themes", id: :string, force: :cascade do |t|
    t.string "name", null: false
    t.string "slug", null: false
    t.text "description"
    t.string "color", default: "#003399"
    t.integer "posts_count", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_themes_on_slug", unique: true
  end

  create_table "users", id: :string, force: :cascade do |t|
    t.string "email", null: false
    t.string "encrypted_password", null: false
    t.string "username", null: false
    t.string "display_name"
    t.text "bio"
    t.string "website"
    t.string "avatar_url"
    t.boolean "is_private", default: false
    t.integer "posts_count", default: 0
    t.integer "followers_count", default: 0
    t.integer "following_count", default: 0
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  create_table "votes", id: :string, force: :cascade do |t|
    t.string "user_id", null: false
    t.string "post_id", null: false
    t.integer "value", default: 1, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["post_id"], name: "index_votes_on_post_id"
    t.index ["user_id", "post_id"], name: "index_votes_on_user_id_and_post_id", unique: true
    t.index ["user_id"], name: "index_votes_on_user_id"
  end

  create_table "webhooks", id: :string, force: :cascade do |t|
    t.string "user_id", null: false
    t.string "url", null: false
    t.text "secret"
    t.text "events", default: "[]"
    t.boolean "active", default: true
    t.datetime "last_triggered_at"
    t.integer "last_status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_webhooks_on_user_id"
  end

  add_foreign_key "api_keys", "users"
  add_foreign_key "bookmarks", "posts"
  add_foreign_key "bookmarks", "users"
  add_foreign_key "follows", "users", column: "followed_id"
  add_foreign_key "follows", "users", column: "follower_id"
  add_foreign_key "invites", "users", column: "invitee_id"
  add_foreign_key "invites", "users", column: "inviter_id"
  add_foreign_key "notifications", "users"
  add_foreign_key "notifications", "users", column: "actor_id"
  add_foreign_key "posts", "posts", column: "parent_id"
  add_foreign_key "posts", "posts", column: "repost_of_id"
  add_foreign_key "posts", "themes"
  add_foreign_key "posts", "users"
  add_foreign_key "votes", "posts"
  add_foreign_key "votes", "users"
  add_foreign_key "webhooks", "users"
end
