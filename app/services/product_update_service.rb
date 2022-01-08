module ProductUpdateService
  extend self

  def update_products(start_date: nil, end_date: nil)
    updates = OmegaService.get_prices(start_date: start_date, end_date: end_date)
    p updates
  end
end
