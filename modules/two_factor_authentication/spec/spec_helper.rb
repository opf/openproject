# -- load spec_helper from OpenProject core
require "spec_helper"

RSpec.configure do |config|
  config.before(:each) do |example|
    next unless example.metadata[:with_2fa_ee]

    allow(EnterpriseToken)
      .to receive(:allows_to?)
      .and_call_original

    allow(EnterpriseToken)
      .to receive(:allows_to?)
      .with(:two_factor_authentication)
      .and_return true
  end
end