RSpec.describe Airbrake::PerformanceBreakdown do
  describe "#stash" do
    subject do
      described_class.new(
        method: 'GET', route: '/', response_type: '', groups: {},
      )
    end

    it { is_expected.to respond_to(:stash) }
  end
end
