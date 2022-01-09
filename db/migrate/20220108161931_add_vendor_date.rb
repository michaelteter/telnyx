class AddVendorDate < ActiveRecord::Migration[7.0]
  def change
    add_column :product_prices, :vendor_date, :datetime, null: false
    add_index  :product_prices, :vendor_date
    add_index  :product_prices, [:vendor_date, :product_id], unique: true
  end
end
