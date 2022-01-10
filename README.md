# README

##Overview

This challenge is comprised of a Rails application which gets data from a remote API
and stores it based on certain business rules, and a Go application which acts as a
demo API server.

There is no frontend on the Rails server.  Exercise of the application is done in the
Rails console, primarily utilizing ProductUpdateService.update_products() method.

Added code has corresponding tests, with 99.1% coverage.  Details are in coverage/index.html,
after rspec has been run.

The Go API server takes a "demo" parameter, allowing the user to demonstrate various
behaviors based on the business rules.  Details of the demo options are in the brief
omega_demo_service/omega.go source file.

##General Assumptions

Spec indicates that we fetch a month range of pricing data, but doesn't specify if a product may have more than
one price change within that period.  Since the data source API does not include a timestamp for the price data,
receiving multiple price entries for the same product in the same period would be ambiguous since we wouldn't know
the time order of those price change events.  Therefore we will assume there will only be zero or one price update
per product per period.

Spec suggests API fetch end_date parameter is "today", and start_date is one month ago.  It doesn't indicate if
"today" should be end of the month.  So it would be possible to fetch a month of data every day (each new "today").
The problem is that if yesterday was the last day of the month, and we did the full month fetch then, and today we
do another fetch (seeing another month's worth of prices, but shifted one day), we could potentially see two price 
changes for the same product.  

The product price could have changed on the last day of our previous fetch.  If the product also changed price today,
and we did another "month" fetch, we would now have two price changes for this one product.  That conflicts with
the previous assumption about having only zero or one price changes per month.  Therefore, we will assume that fetches
will only occur once per month, at the end of each month.  (That also means that if "today" is not the end of a month,
we must only fetch from the first of this month up to today.)  The spec doesn't include fetch scheduling concerns,
so the only change we need to make is to ensure that on whatever day we fetch, we set the start_date to the first day
of the current month.  (If the user/system chose to fetch every day, it would obviously see the same month data
repeatedly, but with one more day of values; the duplicates would be ignored as per the spec.)

##Additions or Changes to Specification

The spec was storing product price in both the products table and the product_prices table.  Storing the current price
in the products table, and keeping (only?) previous prices in the product_prices table would make fetching the 
current prices of products very easy, but it has some drawbacks:

- slightly denormalized schema
- can't get full price history of a product with just a SQL query (unless perhaps it's a very complex query!)
- updating the price of a product requires mutating two tables instead of just the price history table

Therefore, the price data will only be kept in the product_prices table, and the most recent record for a given
product is the "current" price.

If the price history table were very large, it could make sense to define a materialized view that joins
the product and product_prices tables with only the most recent price record for each product.
