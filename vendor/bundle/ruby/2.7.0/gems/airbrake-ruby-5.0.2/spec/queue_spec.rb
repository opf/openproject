RSpec.describe Airbrake::Queue do
  subject { described_class.new(queue: 'bananas', error_count: 0) }

  describe "#ignore" do
    it { is_expected.to respond_to(:ignore!) }
  end

  describe "#stash" do
    it { is_expected.to respond_to(:stash) }
  end

  describe "#route" do
    it "always returns an empty route" do
      queue = described_class.new(queue: 'a', error_count: 0)
      expect(queue.route).to be_empty
    end
  end
end
