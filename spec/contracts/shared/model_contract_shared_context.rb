shared_context 'ModelContract shared context' do # rubocop:disable RSpec/ContextWording
  def expect_contract_valid
    expect(contract.validate)
      .to be(true),
          "Expected contract to be valid. Got invalid contract with the following errors: #{contract.errors.details}"
  end

  def expect_contract_invalid(errors = {})
    expect(contract.validate).to be(false)

    errors.each do |key, error_symbols|
      expect(contract.errors.attribute_names)
        .to include(key), "expected errors attributes #{contract.errors.attribute_names.inspect} to include #{key.inspect}"
      expect(contract.errors.symbols_for(key)).to match_array Array(error_symbols)
    end
  end

  shared_examples 'contract is valid' do
    it 'contract is valid' do
      expect_contract_valid
    end
  end

  shared_examples 'contract is invalid' do |error_symbols = {}|
    example_title = 'contract is invalid'
    example_title << " with #{error_symbols.inspect}" if error_symbols.any?

    it example_title do
      expect_contract_invalid error_symbols
    end
  end

  shared_examples 'contract user is unauthorized' do
    include_examples 'contract is invalid', base: :error_unauthorized
  end

  shared_examples 'contract is valid for active admins and invalid for regular users' do
    context 'when admin' do
      let(:current_user) { build_stubbed(:admin) }

      context 'when active' do
        include_examples 'contract is valid'
      end

      context 'when not active' do
        let(:current_user) { build_stubbed(:admin, status: User.statuses[:locked]) }

        it_behaves_like 'contract user is unauthorized'
      end
    end

    context 'when not admin' do
      let(:current_user) { build_stubbed(:user) }

      it_behaves_like 'contract user is unauthorized'
    end
  end
end
