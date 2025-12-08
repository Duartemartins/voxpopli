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
# Could not dump table "api_keys" because of following StandardError
#   Unknown type 'uuid' for column 'id'


# Could not dump table "bookmarks" because of following StandardError
#   Unknown type 'uuid' for column 'id'


# Could not dump table "follows" because of following StandardError
#   Unknown type 'uuid' for column 'id'


# Could not dump table "invites" because of following StandardError
#   Unknown type 'uuid' for column 'id'


# Could not dump table "notifications" because of following StandardError
#   Unknown type 'uuid' for column 'id'


# Could not dump table "posts" because of following StandardError
#   Unknown type 'uuid' for column 'id'


# Could not dump table "themes" because of following StandardError
#   Unknown type 'uuid' for column 'id'


# Could not dump table "users" because of following StandardError
#   Unknown type 'uuid' for column 'id'


# Could not dump table "votes" because of following StandardError
#   Unknown type 'uuid' for column 'id'


# Could not dump table "webhooks" because of following StandardError
#   Unknown type 'uuid' for column 'id'


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
