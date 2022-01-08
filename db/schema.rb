ActiveRecord::Schema.define(version: 2022_01_08_155604) do

  create_table "product_prices", force: :cascade do |t|
    t.integer "product_id", null: false
    t.integer "price"
    t.decimal "percentage_change"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["product_id"], name: "index_product_prices_on_product_id"
  end

  create_table "products", force: :cascade do |t|
    t.string "vendor_id"
    t.string "name"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["vendor_id"], name: "index_products_on_vendor_id", unique: true
  end

  add_foreign_key "product_prices", "products"
end
