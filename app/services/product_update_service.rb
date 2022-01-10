module ProductUpdateService
  class ProductUpdateServiceException < StandardError; end

  extend self

  def update_products(end_date: nil, demo: nil)
    # Given an end date, fetch all prices from vendor API for the month up to the end date.
    # Insert any new products into products table.
    # Add price records to product_prices table when prices have changed from previous value.

    end_date ||= Date.today
    # end_date could be a string '2022-01-31' or a Date, so ensure it is a Date.
    start_date, end_date = request_period(end_date: end_date.to_date)

    prices = OmegaService.get_prices(start_date: start_date.to_s, end_date: end_date.to_s, demo: demo)

    prices.each do |api_product|
      product = find_or_create_product(api_product: api_product) || next # Skip if no product

      validate_product_name(db_product: product, api_product: api_product) # (Pointless if we just created the product, but low cost and simpler code.)

      update_product_price!(product_id:  product.id,
                            new_price:   OmegaService.product_price(api_product),
                            vendor_date: end_date)
    end
  end

  def find_or_create_product(api_product:)
    product = Product.find_by(vendor_id: OmegaService.product_id(api_product))

    # Skip this product if we don't already have it in our database and it is discontinued.
    return if product.nil? && OmegaService.product_discontinued?(api_product)

    # Return the existing product or create and return it if it isn't in our database yet.
    product || add_new_product!(api_product)
  end

  def update_product_price!(product_id:, new_price:, vendor_date:)
    # If new price is different from most recent stored price, add new price record.
    # (If no previous record exists, then they are different...)

    # Note: if dealing with a large number of products, and if time is more expensive than memory, we can
    #   optimize by fetching the most recent prices for all products.  Then each new price can be compared to
    #   the corresponding product price in the most recent prices cache instead of hitting the db multiple times.
    previous_price, previous_date = most_recent_product_price(product_id: product_id)

    if previous_price != new_price && previous_date != vendor_date
      ProductPrice.create(product_id:        product_id,
                          price:             new_price,
                          percentage_change: percent_price_change(previous_price: previous_price, new_price: new_price),
                          vendor_date:       vendor_date)
    end
  end

  def most_recent_product_price(product_id:)
    # Return the most recent price and vendor_date for the given product id.
    # If no record exists, return zero price and nil date.
    db_product_price = ProductPrice.where(product_id: product_id).order(vendor_date: :desc).first
    [db_product_price&.price, db_product_price&.vendor_date]
  end

  def add_new_product!(api_product)
    # Do not create a new product if the product is discontinued.
    return if OmegaService.product_discontinued?(api_product)

    # Assumes product does not already exist in db.  If it does exist, db will give a duplicate record error.
    Product.create(vendor_id: OmegaService.product_id(api_product),
                   name:      OmegaService.product_name(api_product))
  end

  def request_period(end_date: nil)
    # Return a start/end date pair for the month up to the provided end_date.
    # If no end_date is provided, return current month period.
    end_date ||= Date.today
    start_date = end_date - end_date.mday + 1
    [start_date, end_date]
  end

  def validate_product_name(db_product:, api_product:)
    if db_product.name != api_product['name']
      raise ProductUpdateServiceException,
            "Product [#{db_product.vendor_id}] name conflict: [#{db_product.name}] / [#{api_product['name']}]"
    end
  end

  def percent_price_change(previous_price:, new_price:)
    # There may be no previous price, so default it to zero.
    previous_price ||= 0

    # If prev or new price is zero, we can't calculate % change; just report 0.
    previous_price * new_price == 0 ? 0.0 : (1.0 * (new_price - previous_price) / previous_price) * 100.0
  end
end
