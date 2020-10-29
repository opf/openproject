RSpec.describe Airbrake::Request do
  describe "#stash" do
    subject do
      described_class.new(method: 'GET', route: '/', status_code: 200)
    end

    it { is_expected.to respond_to(:stash) }
  end
end
