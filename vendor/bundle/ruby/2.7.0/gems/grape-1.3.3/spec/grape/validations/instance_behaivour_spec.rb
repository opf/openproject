# frozen_string_literal: true

require 'spec_helper'

describe 'Validator with instance variables' do
  let(:validator_type) do
    Class.new(Grape::Validations::Base) do
      def validate_param!(_attr_name, _params)
        if instance_variable_defined?(:@instance_variable) && @instance_variable
          raise Grape::Exceptions::Validation.new(params: ['params'],
                                                  message: 'This should never happen')
        end
        @instance_variable = true
      end
    end
  end

  before do
    Grape::Validations.register_validator('instance_validator', validator_type)
  end

  after do
    Grape::Validations.deregister_validator('instance_validator')
  end

  let(:app) do
    Class.new(Grape::API) do
      params do
        optional :param_to_validate, instance_validator: true
        optional :another_param_to_validate, instance_validator: true
      end
      get do
        'noop'
      end
    end
  end

  it 'passes validation every time' do
    expect(validator_type).to receive(:new).exactly(4).times.and_call_original

    2.times do
      get '/', param_to_validate: 'value', another_param_to_validate: 'value'
      expect(last_response.status).to eq 200
    end
  end
end
