# frozen_string_literal: true

require "spec_helper"

# Contracts are Disposable twins: building one reads every declared attribute from the model.
# A write-only attribute without a reader (0016: remove_token) made every CI connection create and
# update raise NoMethodError, in Project settings and in APIv3 (0019b).
RSpec.describe TestManagement::CiConnections::CreateContract do
  shared_let(:project) { create(:project, enabled_module_names: %i[test_management]) }
  shared_let(:user) { create(:user, member_with_permissions: { project => %i[view_test_cases manage_test_ci] }) }

  it "builds the create and update contracts for a connection" do
    connection = TestManagement::CiConnection.new(project:, name: "Shop", provider: "github", repository: "my-org/shop")

    expect { described_class.new(connection, user) }.not_to raise_error
    expect { TestManagement::CiConnections::UpdateContract.new(connection, user) }.not_to raise_error
  end

  it "validates a form-like write with the remove flags" do
    connection = TestManagement::CiConnection.new(project:)
    connection.attributes = { name: "Shop", provider: "github", repository: "my-org/shop", token: "ghp_x",
                              remove_token: "0", remove_trigger_token: "0" }

    expect(described_class.new(connection, user).validate).to be(true)
  end

  it "builds every module contract with its own model" do
    contracts = Dir[OpenProject::TestManagement::Engine.root.join("app/contracts/test_management/**/*_contract.rb")].map do |path|
      path.delete_prefix("#{OpenProject::TestManagement::Engine.root.join('app/contracts')}/").delete_suffix(".rb").camelize.constantize
    end
    with_model = contracts.select do |klass|
      klass.respond_to?(:model) && klass.method(:model).source_location&.first.to_s.include?("test_management")
    end

    expect(with_model.size).to be >= 15
    with_model.each do |klass|
      expect { klass.new(klass.model.new, user) }.not_to raise_error, klass.name
    end
  end
end
