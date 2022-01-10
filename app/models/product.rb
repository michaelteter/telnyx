class Product < ApplicationRecord
  has_many :historical_prices, foreign_key: 'product_id', class_name: 'ProductPrice'
end
