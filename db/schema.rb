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

ActiveRecord::Schema.define(version: 2022_01_08_161931) do

  create_table "product_prices", force: :cascade do |t|
    t.integer "product_id", null: false
    t.integer "price"
    t.decimal "percentage_change"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.datetime "vendor_date", precision: 6, null: false
    t.index ["product_id"], name: "index_product_prices_on_product_id"
    t.index ["vendor_date", "product_id"], name: "index_product_prices_on_vendor_date_and_product_id", unique: true
    t.index ["vendor_date"], name: "index_product_prices_on_vendor_date"
  end

  create_table "products", force: :cascade do |t|
    t.string "vendor_id"
    t.string "index"
    t.string "name"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["vendor_id"], name: "index_products_on_vendor_id", unique: true
  end

  add_foreign_key "product_prices", "products"
end
