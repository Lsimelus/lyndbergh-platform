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

ActiveRecord::Schema[8.1].define(version: 2026_11_20_020000) do
  create_table "checks", force: :cascade do |t|
    t.string "site_slug", null: false
    t.boolean "ok", null: false
    t.integer "http_status"
    t.integer "latency_ms"
    t.string "error"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["site_slug"], name: "index_checks_on_site_slug"
  end

  create_table "contact_messages", force: :cascade do |t|
    t.string "site", default: "portfolio", null: false
    t.string "name", null: false
    t.string "email", null: false
    t.string "subject", null: false
    t.text "message", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_contact_messages_on_created_at"
  end

  create_table "feedback", force: :cascade do |t|
    t.string "site", null: false
    t.integer "rating"
    t.text "comment"
    t.string "page"
    t.string "user_ref"
    t.string "email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["site", "created_at"], name: "index_feedback_on_site_and_created_at"
    t.index ["site", "user_ref"], name: "index_feedback_on_site_and_user_ref"
  end

  create_table "traffic_minutes", force: :cascade do |t|
    t.string "site_slug", null: false
    t.datetime "minute", null: false
    t.integer "requests", default: 0, null: false
    t.integer "errors_4xx", default: 0, null: false
    t.integer "errors_5xx", default: 0, null: false
    t.float "total_ms", default: 0.0, null: false
    t.float "max_ms", default: 0.0, null: false
    t.index ["minute"], name: "index_traffic_minutes_on_minute"
    t.index ["site_slug", "minute"], name: "index_traffic_minutes_on_site_slug_and_minute", unique: true
  end
end
