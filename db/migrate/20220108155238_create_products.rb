class CreateProducts < ActiveRecord::Migration[7.0]
  def change
    create_table :products do |t|
      t.string :vendor_id, :index, unique: true
      t.string :name

      t.timestamps
    end
    add_index :products, :vendor_id, unique: true
  end
end
