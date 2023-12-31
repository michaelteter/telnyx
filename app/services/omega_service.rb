require 'http'

=begin

Service Description

This module facilitates getting price data from the Omega pricing vendor.

It is designed to shield the user from having to know any details about the returned data.

get_prices() is the primary method for fetching prices for a given period.
product_id(), product_price(), and product_name() provide the corresponding data without the caller needing to know
the details of the data.

Assumptions:

Based on the sample API output in the challenge, it appears that there is no date associated with the returned records.
That implies that for any fetched period (one month, based on the challenge description), a product may appear
zero or one time in the results.  We will assume that is the case.

Additionally, we will store the end_date as "vendor_date" in the price records.  We should not rely on insert/update
timestamps because those reflect when records were created/modified in the database, not necessarily when
they were fetched from the remote price service.  That will allow reliably date-ordered queries in the future.

Minor optimization:

In all cases where there is updated price data the price data will be
added to the historical table (including the "current" price).  The
alternative would be to only store the current price in the current product
table, and later "move" that price to the historical table as a newer price
arrived.  But storing all prices in the history table has two benefits:
1. It reduces the number of database operations.
2. We can always look at the historical price table to see prices any point in time, from
  most recent (current) to older.

=end

module OmegaService
  class OmegaServiceException < StandardError; end

  extend self

  PRICE_RADIX = '.'

  # API_HOST = 'https://omegapricinginc.com'
  API_HOST = 'http://localhost:8080'
  API_PATH = "#{API_HOST}/pricing/records.json"
  API_KEY  = Rails.application.credentials.omega_api.api_key

  def get_prices(start_date: nil, end_date: nil, demo: nil)
    # Demo is temporary during development.
    # It allows us to tell the vendor API server to provide special results to test different behaviors.
    # To see what special behaviors exist, read the omega.go server file. :)
    prices = remote_prices(start_date: start_date,
                           end_date:   end_date,
                           demo:       demo)&.[]('productRecords')
    raise OmegaServiceException, "Failed to get Omega prices for period [#{start_date}]-[#{end_date}]." unless prices.present?
    prices
  end

  def remote_prices(start_date:, end_date:, demo:)
    response = HTTP.get(API_PATH, params: { api_key:    API_KEY,
                                            start_date: start_date,
                                            end_date:   end_date,
                                            demo:       demo })
    response&.parse
  end

  def price_in_cents(dollar_price, radix: PRICE_RADIX)
    dollars, cents = dollar_price.gsub(/[^\d#{Regexp.quote(radix)}]/, '').split(radix)
    dollars.to_i * 100 + cents.to_i
  end

  def product_id(api_product) api_product['id'] end

  def product_price(api_product) price_in_cents(api_product['price']) end

  def product_name(api_product) api_product['name'] end

  def product_discontinued?(api_product) api_product['discontinued'] end
end
