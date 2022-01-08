require 'http'

=begin

Assumptions:

Based on the sample API output in the challenge, it appears that there is no date associated with the returned records.
That implies that for any fetched period (one month, based on the challenge description), a product may appear
zero or one time in the results.  We will assume that is the case.

Additionally, we will store the end_date as "price_date" in the price records.  We should not rely on insert/update
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

  API_PATH = 'http://localhost:8080/pricing/records.json'
  API_KEY = Rails.application.credentials.omega_api.api_key

  def get_prices(start_date: nil, end_date: nil)
    response = HTTP.get(API_PATH, params: { api_key: API_KEY, start_date: start_date, end_date: end_date })
    response.parse
  end
end
