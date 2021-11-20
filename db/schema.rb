# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2021_11_20_222001) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "events", force: :cascade do |t|
    t.integer "sport"
    t.integer "winner"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.json "team1", default: [], array: true
    t.json "team2", default: [], array: true
    t.float "team1InitialRating"
    t.float "team2InitialRating"
  end

  create_table "sports", force: :cascade do |t|
    t.string "name"
    t.string "alternate_name"
    t.json "participants", default: [], array: true
    t.json "events", default: [], array: true
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "wordForPlayer"
  end

  create_table "users", force: :cascade do |t|
    t.string "username"
    t.string "email"
    t.string "firstname"
    t.string "lastname"
    t.string "password_digest"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.json "events", default: [], array: true
    t.json "sports", default: [], array: true
  end

end
