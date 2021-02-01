shared_context 'ModelContract shared context' do
  def expect_contract_valid
    expect(contract.validate).to eq(true)
  end

  def expect_contract_invalid(errors = {})
    expect(contract.validate).to eq(false)

    errors.each do |key, error_symbols|
      expect(contract.errors.symbols_for(key)).to match_array Array(error_symbols)
    end
  end

  shared_examples 'contract is valid' do
    it do
      expect_contract_valid
    end
  end

  shared_examples 'contract is invalid' do |errors = {}|
    it do
      expect_contract_invalid errors
    end
  end

  shared_examples 'contract user is unauthorized' do
    it do
      expect_contract_invalid base: :error_unauthorized
    end
  end
end
