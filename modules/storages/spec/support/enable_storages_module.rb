RSpec.shared_context "with storages module enabled" do
  before do
    allow(OpenProject::FeatureDecisions).to receive(:storages_module_active?).and_return(true)
  end
end

RSpec.configure do |rspec|
  rspec.include_context "with storages module enabled", enable_storages: true
end
