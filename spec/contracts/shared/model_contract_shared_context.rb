shared_context 'ModelContract shared context' do
  def expect_contract_valid
    expect(contract.validate)
      .to eq(true),
          "Contract is invalid with the following errors: #{contract.errors.details}"
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

  shared_examples 'contract is valid for active admins and invalid for regular users' do
    context 'when admin' do
      let(:current_user) { FactoryBot.build_stubbed(:admin) }

      context 'when admin active' do
        it_behaves_like 'contract is valid'
      end

      context 'when admin not active' do
        let(:current_user) { FactoryBot.build_stubbed(:admin, status: User.statuses[:locked]) }

        it_behaves_like 'contract user is unauthorized'
      end
    end

    context 'when not admin' do
      let(:current_user) { FactoryBot.build_stubbed(:user) }

      it_behaves_like 'contract user is unauthorized'
    end
  end
end
