# -- load spec_helper from OpenProject core
require "spec_helper"

RSpec.configure do |config|
  config.before(:each) do |example|
    next unless example.metadata[:with_group_ee]

    allow(EnterpriseToken)
        .to receive(:allows_to?)
        .and_call_original

    allow(EnterpriseToken)
        .to receive(:allows_to?)
        .with(:ldap_groups)
        .and_return true
  end
end