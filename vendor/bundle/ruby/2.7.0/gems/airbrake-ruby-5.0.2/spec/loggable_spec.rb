RSpec.describe Airbrake::Loggable do
  describe ".instance" do
    it "returns a logger" do
      expect(described_class.instance).to be_a(Logger)
    end
  end

  describe "#logger" do
    let(:subject) do
      Class.new { include Airbrake::Loggable }.new
    end

    it "returns a logger that has Logger::WARN severity" do
      expect(subject.logger.level).to eq(Logger::WARN)
    end
  end
end
