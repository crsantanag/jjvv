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

ActiveRecord::Schema[7.2].define(version: 2025_11_25_142905) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "addresses", force: :cascade do |t|
    t.string "street"
    t.string "description"
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.float "latitude"
    t.float "longitude"
    t.date "fecha_inicio"
    t.integer "ult_mes_pagado"
    t.integer "ult_ano_pagado"
    t.index ["user_id"], name: "index_addresses_on_user_id"
  end

  create_table "apartments", force: :cascade do |t|
    t.integer "number"
    t.string "description"
    t.date "start_date"
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "address_id"
    t.string "ap_paterno"
    t.string "ap_materno"
    t.string "nombre"
    t.integer "edad"
    t.string "estado_civil"
    t.string "profesion"
    t.string "domicilio"
    t.integer "rut"
    t.string "dv"
    t.string "telefono"
    t.string "estado"
    t.integer "ult_mes_pagado"
    t.integer "ult_ano_pagado"
    t.index ["address_id"], name: "index_apartments_on_address_id"
    t.index ["user_id"], name: "index_apartments_on_user_id"
  end

  create_table "bills", force: :cascade do |t|
    t.date "date"
    t.integer "tipo_egreso"
    t.string "comment"
    t.integer "amount", default: 0
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "apartment_id"
    t.index ["apartment_id"], name: "index_bills_on_apartment_id"
    t.index ["user_id"], name: "index_bills_on_user_id"
  end

  create_table "deposits", force: :cascade do |t|
    t.date "date"
    t.integer "tipo_ingreso"
    t.string "comment"
    t.integer "amount", default: 0
    t.integer "mes"
    t.integer "ano"
    t.bigint "user_id", null: false
    t.bigint "apartment_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["apartment_id"], name: "index_deposits_on_apartment_id"
    t.index ["user_id"], name: "index_deposits_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name_community"
    t.string "type_community"
    t.integer "saldo_inicial", default: 0
    t.string "name"
    t.integer "role", default: 0
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "addresses", "users"
  add_foreign_key "apartments", "addresses"
  add_foreign_key "apartments", "users"
  add_foreign_key "bills", "apartments"
  add_foreign_key "bills", "users"
  add_foreign_key "deposits", "apartments"
  add_foreign_key "deposits", "users"
end
