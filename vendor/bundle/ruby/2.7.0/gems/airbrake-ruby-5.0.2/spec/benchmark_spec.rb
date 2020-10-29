RSpec.describe Airbrake::Benchmark do
  describe ".measure" do
    it "returns measured performance time" do
      expect(described_class.measure { '10' * 10 }).to be_kind_of(Numeric)
    end
  end

  describe "#stop" do
    before { subject }

    context "when called one time" do
      its(:stop) { is_expected.to eq(true) }
    end

    context "when called twice or more" do
      before { subject.stop }

      its(:stop) { is_expected.to eq(false) }
    end
  end

  describe "#duration" do
    context "when #stop wasn't called yet" do
      its(:duration) { is_expected.to be_zero }
    end

    context "when #stop was called" do
      before { subject.stop }

      its(:duration) { is_expected.to be > 0 }
    end
  end
end
