require 'spec_helper'

describe DeprecatedAlias do

  let(:clazz) {
    Class.new do
      extend DeprecatedAlias

      def secret_key
        @secret_key ||= 'happiness'
      end
      deprecated_alias :special_key, :secret_key
    end
  }

  subject(:object) { clazz.new }

  let(:deprecation_warning) {
    "special_key is deprecated and will be removed in a future OpenProject version. " +
    "Please use secret_key instead."
  }

  before do
    expect(ActiveSupport::Deprecation).to receive(:warn)
      .with(deprecation_warning, an_instance_of(Array))
  end

  it 'should alias the method' do
    expect(object.special_key).to eq('happiness')
  end

end
