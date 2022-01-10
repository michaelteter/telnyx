require 'rails_helper'

describe 'ProductUpdateService' do
  before(:all) do
    @api_product  = { 'name'         => 'Recliner',
                      'category'     => 'chair',
                      'price'        => '$50.00',
                      'id'           => '443322',
                      'discontinued' => false }
    @api_product2 = { 'name'         => 'Wood Table',
                      'category'     => 'table',
                      'price'        => '$120.50',
                      'id'           => '808606',
                      'discontinued' => false }
    @api_product3 = { 'name'         => 'Stool',
                      'category'     => 'chair',
                      'price'        => '$900.00',
                      'id'           => '999999',
                      'discontinued' => true }
    @api_products = [@api_product, @api_product2, @api_product3]
  end

  describe 'update products' do
    it 'creates products and stores their first price records' do
      allow(OmegaService).to receive(:get_prices).and_return(@api_products)
      ProductUpdateService.update_products

      expect(Product.count).to eq(2) # One of the products was discontinued and wasn't created.
      expect(ProductPrice.count).to eq(2) # One price for each created product
    end

    it 'adds new price records for existing products' do
      allow(OmegaService).to receive(:get_prices).and_return(@api_products)
      ProductUpdateService.update_products(end_date: Date.today - 1.day)

      prices = [@api_product.merge('price' => '$100.00'),
                @api_product2.merge('price' => '$241.00')]
      allow(OmegaService).to receive(:get_prices).and_return(prices)
      ProductUpdateService.update_products(end_date: Date.today)

      expect(ProductPrice.count).to eq(4)
    end

    it 'updates prices for products where prices have changed' do
      allow(OmegaService).to receive(:get_prices).and_return(@api_products)
      ProductUpdateService.update_products(end_date: Date.today - 1.day)

      prices = [@api_product,
                @api_product2.merge('price' => '$241.00')]
      allow(OmegaService).to receive(:get_prices).and_return(prices)
      ProductUpdateService.update_products(end_date: Date.today)

      # first product price didn't change, so no new price would have been added
      expect(ProductPrice.count).to eq(3)
    end

    it 'does not update price for non-existent product' do
      allow(OmegaService).to receive(:get_prices).and_return(@api_products)
      ProductUpdateService.update_products(end_date: Date.today - 1.day)
      # 2 products inserted, 1 ignored since it was discontinued.
      expect(Product.count).to eq(2)
      expect(ProductPrice.count).to eq(2)

      prices = [@api_product3.merge('price' => '$111.11')]
      allow(OmegaService).to receive(:get_prices).and_return(prices)
      ProductUpdateService.update_products(end_date: Date.today)
      # One price update was for a product which doesn't exist in our database; not adding price record.
      expect(ProductPrice.count).to eq(2)
    end

    it 'fails upon encountering product which has changed name' do
      allow(OmegaService).to receive(:get_prices).and_return(@api_products)
      ProductUpdateService.update_products(end_date: Date.today - 1.day)

      prices = [@api_product.merge('price' => '$100.00'),
                @api_product2.merge('name' => 'Broken Lamp', 'price' => '$241.00')]
      allow(OmegaService).to receive(:get_prices).and_return(prices)
      expect { ProductUpdateService.update_products(end_date: Date.today) }.to \
        raise_exception(ProductUpdateService::ProductUpdateServiceException)
    end
  end

  describe 'update product price' do
    it 'saves a product price when no prior prices exist' do
      product = ProductUpdateService.add_new_product!(@api_product)
      expect(product.historical_prices.count).to eq(0)

      ProductUpdateService.update_product_price!(product_id:  product.id,
                                                 new_price:   OmegaService.product_price(@api_product),
                                                 vendor_date: Date.today)
      expect(product.historical_prices.count).to eq(1)
    end

    it 'saves a product price when prior exist and new price differs from most recent price' do
      product = ProductUpdateService.add_new_product!(@api_product)
      expect(product.historical_prices.count).to eq(0)

      ProductUpdateService.update_product_price!(product_id:  product.id,
                                                 new_price:   OmegaService.product_price(@api_product),
                                                 vendor_date: Date.today - 1.day)
      ProductUpdateService.update_product_price!(product_id:  product.id,
                                                 new_price:   2 * OmegaService.product_price(@api_product),
                                                 vendor_date: Date.today)
      expect(product.historical_prices.count).to eq(2)
    end

    it 'does not save a price when prior exists and most recent price is same as new price' do
      product = ProductUpdateService.add_new_product!(@api_product)
      expect(product.historical_prices.count).to eq(0)

      ProductUpdateService.update_product_price!(product_id:  product.id,
                                                 new_price:   OmegaService.product_price(@api_product),
                                                 vendor_date: Date.today - 1.day)
      expect(product.historical_prices.count).to eq(1)
      ProductUpdateService.update_product_price!(product_id:  product.id,
                                                 new_price:   OmegaService.product_price(@api_product),
                                                 vendor_date: Date.today)
      expect(product.historical_prices.count).to eq(1)
    end

    it 'does not save a price when a price already exists for that vendor date' do
      product = ProductUpdateService.add_new_product!(@api_product)
      expect(product.historical_prices.count).to eq(0)

      ProductUpdateService.update_product_price!(product_id:  product.id,
                                                 new_price:   OmegaService.product_price(@api_product),
                                                 vendor_date: Date.today)
      expect(product.historical_prices.count).to eq(1)
      ProductUpdateService.update_product_price!(product_id:  product.id,
                                                 new_price:   2 * OmegaService.product_price(@api_product),
                                                 vendor_date: Date.today)
      expect(product.historical_prices.count).to eq(1)
    end
  end

  describe 'find or create product' do
    it 'finds an existing product' do
      product = Product.create(vendor_id: OmegaService.product_id(@api_product),
                               name:      OmegaService.product_name(@api_product))
      found_product = ProductUpdateService.find_or_create_product(api_product: @api_product)

      expect(found_product).to eq(product)
    end

    it 'does not create a product when not already existing and discontinued' do
      existing_product = Product.find_by(vendor_id: OmegaService.product_id(@api_product))
      expect(existing_product).to eq(nil)

      product = ProductUpdateService.find_or_create_product(api_product: @api_product.merge('discontinued' => true))
      expect(product).to eq(nil)
      found_product = Product.find_by(vendor_id: OmegaService.product_id(@api_product))
      expect(found_product).to eq(nil)
    end

    it 'creates a product when not already existing and not discontinued' do
      existing_product = Product.find_by(vendor_id: OmegaService.product_id(@api_product))
      expect(existing_product).to eq(nil)

      product = ProductUpdateService.find_or_create_product(api_product: @api_product)
      found_product = Product.find_by(vendor_id: OmegaService.product_id(@api_product))
      expect(product.vendor_id).to eq(found_product.vendor_id)
    end
  end

  describe 'most recent product price' do
    it 'gets the most recent price' do
      product = ProductUpdateService.add_new_product!(@api_product)

      # Intentionally inserted out of order
      price1 = ProductPrice.create(product_id: product.id,
                                   price: 10000,
                                   percentage_change: 100.0,
                                   vendor_date: Date.today - 1.day)
      price2 = ProductPrice.create(product_id: product.id,
                                   price: 7500,
                                   percentage_change: -25.00,
                                   vendor_date: Date.today)
      price0 = ProductPrice.create(product_id: product.id,
                                   price: 5000,
                                   percentage_change: 0.0,
                                   vendor_date: Date.today - 2.days)

      most_recent_price, vendor_date = ProductUpdateService.most_recent_product_price(product_id: product.id)

      expect(most_recent_price).to eq(7500)
      expect(vendor_date).to eq(Date.today)
    end

    it 'gets nothing when product/price not found' do
      most_recent_price, vendor_date = ProductUpdateService.most_recent_product_price(product_id: 0)

      expect(most_recent_price).to eq(nil)
      expect(vendor_date).to eq(nil)
    end
  end

  describe 'add new product' do
    it 'adds a product' do
      n = Product.count
      product = ProductUpdateService.add_new_product!(@api_product)
      expect(product.vendor_id).to eq('443322')
      expect(Product.count).to eq(n + 1)
    end

    it 'does not add a discontinued product' do
      n = Product.count
      product = ProductUpdateService.add_new_product!(@api_product.merge('discontinued' => true))
      expect(product).to eq(nil)
      expect(Product.count).to eq(n)
    end
  end

  describe 'request period' do
    it 'determines request period given specific end date' do
      start_date = Date.new(2022, 01, 01)
      end_date = Date.new(2022, 01, 12)
      expect(ProductUpdateService.request_period(end_date: end_date)).to eq([start_date, end_date])
    end

    it 'determines request period given no end date' do
      today = Date.today
      start_date = Date.new(today.year, today.month, 01)
      expect(ProductUpdateService.request_period()).to eq([start_date, today])
    end
  end

  describe 'validate product name' do
    it 'validates matching product name' do
      db_product = Product.new(name: 'Recliner')
      expect(ProductUpdateService.validate_product_name(db_product: db_product, api_product: @api_product)).to \
        eq(nil)
    end

    it 'raises an exception if names do not match' do
      db_product = Product.new(name: 'Stool')
      expect { ProductUpdateService.validate_product_name(db_product: db_product, api_product: @api_product) }.to \
        raise_exception(ProductUpdateService::ProductUpdateServiceException)
    end
  end

  describe "calculate percent price change" do
    it 'calculates positive percent price change' do
      expect(ProductUpdateService.percent_price_change(previous_price: 100, new_price: 110)).to eq(10.0)
    end

    it 'calculates negative percent price change' do
      expect(ProductUpdateService.percent_price_change(previous_price: 100, new_price: 90)).to eq(-10.0)
    end

    it 'handles impossible calculations' do
      expect(ProductUpdateService.percent_price_change(previous_price: 0,   new_price: 100)).to eq(0.0)
      expect(ProductUpdateService.percent_price_change(previous_price: 100, new_price: 0)).to eq(0.0)
      expect(ProductUpdateService.percent_price_change(previous_price: 0,   new_price: 0)).to eq(0.0)
      expect(ProductUpdateService.percent_price_change(previous_price: nil, new_price: 0)).to eq(0.0)
    end
  end
end
