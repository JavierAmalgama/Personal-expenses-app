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

ActiveRecord::Schema[7.1].define(version: 2026_10_14_130000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "movements", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "kind", null: false
    t.date "date", null: false
    t.string "description", null: false
    t.decimal "amount", precision: 12, scale: 2, null: false
    t.string "currency", default: "ARS", null: false
    t.string "category"
    t.string "subcategory"
    t.string "payment_method"
    t.string "credit_card"
    t.string "beneficiary"
    t.text "notes"
    t.boolean "shared", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "category"], name: "index_movements_on_user_id_and_category"
    t.index ["user_id", "date"], name: "index_movements_on_user_id_and_date"
    t.index ["user_id"], name: "index_movements_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "name", null: false
    t.string "email", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  create_table "users_tokens", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "token", null: false
    t.datetime "valid_until"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["token"], name: "index_users_tokens_on_token", unique: true
    t.index ["user_id"], name: "index_users_tokens_on_user_id"
  end

  add_foreign_key "movements", "users", on_delete: :cascade
  add_foreign_key "users_tokens", "users", on_delete: :cascade
end
