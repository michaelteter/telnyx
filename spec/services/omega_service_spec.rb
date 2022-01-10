require 'rails_helper'

describe 'OmegaService' do
  describe 'remote API price fetch' do
    it 'gets prices' do
      sample = { 'productRecords' => [:placeholder] }

      allow(OmegaService).to receive(:remote_prices).and_return(sample)
      expect(OmegaService.get_prices).to eq([:placeholder])
    end

    it 'complains when no results are returned' do
      no_results = { 'productRecords' => [] }

      allow(OmegaService).to receive(:remote_prices).and_return(no_results)
      expect { OmegaService.get_prices }.to raise_error(OmegaService::OmegaServiceException)
    end

    it 'complains when invalid or no response is returned' do
      allow(OmegaService).to receive(:remote_prices).and_return(nil)
      expect { OmegaService.get_prices }.to raise_error(OmegaService::OmegaServiceException)
    end
  end

  describe 'wrapped accessors' do
    it 'gets product id' do
      expect(OmegaService.product_id({ 'id' => 234567 })).to eq(234567)
    end

    it 'gets product name' do
      expect(OmegaService.product_name({ 'name' => 'Fancy Chair' })).to eq('Fancy Chair')
    end

    it 'gets product price' do
      expect(OmegaService.product_price({ 'price' => '$12.34' })).to eq(1234)
    end

    it 'gets product discontinued' do
      expect(OmegaService.product_discontinued?({ 'discontinued' => false })).to eq(false)
    end
  end

  describe 'string dollar conversion to cents' do
    it 'handles standard case' do
      expect(OmegaService.price_in_cents('$86753.09')).to eq(8675309)
    end

    it 'handles zero prices' do
      expect(OmegaService.price_in_cents('$0')).to eq(0)
      expect(OmegaService.price_in_cents('$0.0')).to eq(0)
      expect(OmegaService.price_in_cents('$0.00')).to eq(0)
    end

    it 'handles alternative radix' do
      expect(OmegaService.price_in_cents('$86753,09', radix: ',')).to eq(8675309)
    end
  end
end
