RSpec.shared_context 'status collection representer' do |self_link|
  let(:statuses)  { FactoryGirl.build_list(:status, 3) }
  let(:representer) { described_class.new(statuses, 42, self_link) }
end
