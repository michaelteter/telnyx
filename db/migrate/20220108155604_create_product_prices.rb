class CreateProductPrices < ActiveRecord::Migration[7.0]
  def change
    create_table :product_prices do |t|
      t.references :product, null: false, foreign_key: true
      t.integer :price
      t.decimal :percentage_change

      t.timestamps
    end
  end
end
