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

ActiveRecord::Schema[7.1].define(version: 2026_11_05_120200) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  # Custom types defined in this database.
  # Note that some types may not work with other database engines. Be careful if changing database.
  create_enum "credit_card_brand", ["visa", "amex", "mercado_pago", "other"]
  create_enum "currency", ["ARS", "USD"]
  create_enum "movement_kind", ["income", "expense"]
  create_enum "payment_method", ["cash", "debit_card", "credit_card", "transfer", "other"]

  create_table "categories", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "parent_id"
    t.string "name", null: false
    t.enum "kind", null: false, enum_type: "movement_kind"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["parent_id"], name: "index_categories_on_parent_id"
    t.index ["user_id", "parent_id", "name"], name: "index_categories_on_user_id_and_parent_id_and_name", unique: true, nulls_not_distinct: true
    t.index ["user_id"], name: "index_categories_on_user_id"
  end

  create_table "events", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_events_on_user_id"
  end

  create_table "movements", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.enum "kind", null: false, enum_type: "movement_kind"
    t.date "date", null: false
    t.string "description", null: false
    t.decimal "amount", precision: 12, scale: 2, null: false
    t.enum "currency", default: "ARS", null: false, enum_type: "currency"
    t.enum "payment_method", enum_type: "payment_method"
    t.enum "credit_card", enum_type: "credit_card_brand"
    t.string "beneficiary"
    t.text "notes"
    t.boolean "shared", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "category_id"
    t.bigint "event_id"
    t.jsonb "offset_data"
    t.index ["category_id"], name: "index_movements_on_category_id"
    t.index ["event_id"], name: "index_movements_on_event_id"
    t.index ["offset_data"], name: "index_movements_on_offset_data", opclass: :jsonb_path_ops, using: :gin
    t.index ["user_id", "date"], name: "index_movements_on_user_id_and_date"
  end

  create_table "user_settings", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.decimal "monthly_budget", precision: 12, scale: 2
    t.enum "budget_currency", default: "ARS", null: false, enum_type: "currency"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_user_settings_on_user_id", unique: true
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

  add_foreign_key "categories", "categories", column: "parent_id", on_delete: :cascade
  add_foreign_key "categories", "users", on_delete: :cascade
  add_foreign_key "events", "users", on_delete: :cascade
  add_foreign_key "movements", "categories", on_delete: :nullify
  add_foreign_key "movements", "events", on_delete: :nullify
  add_foreign_key "movements", "users", on_delete: :cascade
  add_foreign_key "user_settings", "users", on_delete: :cascade
  add_foreign_key "users_tokens", "users", on_delete: :cascade
end
