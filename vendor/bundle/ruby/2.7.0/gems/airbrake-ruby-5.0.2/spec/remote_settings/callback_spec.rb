RSpec.describe Airbrake::RemoteSettings::Callback do
  describe "#call" do
    let(:logger) { Logger.new(File::NULL) }

    let(:config) do
      Airbrake::Config.new(
        project_id: 123,
        logger: logger,
      )
    end

    let(:data) do
      instance_double(Airbrake::RemoteSettings::SettingsData)
    end

    before do
      allow(data).to receive(:to_h)
      allow(data).to receive(:error_host)
      allow(data).to receive(:apm_host)
      allow(data).to receive(:error_notifications?)
      allow(data).to receive(:performance_stats?)
    end

    it "logs given data" do
      expect(logger).to receive(:debug).with(/applying remote settings/)
      described_class.new(config).call(data)
    end

    context "when the config disables error notifications" do
      before do
        config.error_notifications = false
        allow(data).to receive(:error_notifications?).and_return(true)
      end

      it "keeps the option disabled forever" do
        callback = described_class.new(config)

        callback.call(data)
        expect(config.error_notifications).to eq(false)

        callback.call(data)
        expect(config.error_notifications).to eq(false)

        callback.call(data)
        expect(config.error_notifications).to eq(false)
      end
    end

    context "when the config enables error notifications" do
      before { config.error_notifications = true }

      it "can disable and enable error notifications" do
        expect(data).to receive(:error_notifications?).and_return(false)

        callback = described_class.new(config)
        callback.call(data)
        expect(config.error_notifications).to eq(false)

        expect(data).to receive(:error_notifications?).and_return(true)
        callback.call(data)
        expect(config.error_notifications).to eq(true)
      end
    end

    context "when the config disables performance_stats" do
      before do
        config.performance_stats = false
        allow(data).to receive(:performance_stats?).and_return(true)
      end

      it "keeps the option disabled forever" do
        callback = described_class.new(config)

        callback.call(data)
        expect(config.performance_stats).to eq(false)

        callback.call(data)
        expect(config.performance_stats).to eq(false)

        callback.call(data)
        expect(config.performance_stats).to eq(false)
      end
    end

    context "when the config enables performance stats" do
      before { config.performance_stats = true }

      it "can disable and enable performance_stats" do
        expect(data).to receive(:performance_stats?).and_return(false)

        callback = described_class.new(config)
        callback.call(data)
        expect(config.performance_stats).to eq(false)

        expect(data).to receive(:performance_stats?).and_return(true)
        callback.call(data)
        expect(config.performance_stats).to eq(true)
      end
    end

    context "when error_host returns a value" do
      it "sets the error_host option" do
        config.error_host = 'http://api.airbrake.io'
        allow(data).to receive(:error_host).and_return('https://api.example.com')

        described_class.new(config).call(data)
        expect(config.error_host).to eq('https://api.example.com')
      end
    end

    context "when error_host returns nil" do
      it "doesn't modify the error_host option" do
        config.error_host = 'http://api.airbrake.io'
        allow(data).to receive(:error_host).and_return(nil)

        described_class.new(config).call(data)
        expect(config.error_host).to eq('http://api.airbrake.io')
      end
    end

    context "when apm_host returns a value" do
      it "sets the apm_host option" do
        config.apm_host = 'http://api.airbrake.io'
        allow(data).to receive(:apm_host).and_return('https://api.example.com')

        described_class.new(config).call(data)
        expect(config.apm_host).to eq('https://api.example.com')
      end
    end

    context "when apm_host returns nil" do
      it "doesn't modify the apm_host option" do
        config.apm_host = 'http://api.airbrake.io'
        allow(data).to receive(:apm_host).and_return(nil)

        described_class.new(config).call(data)
        expect(config.apm_host).to eq('http://api.airbrake.io')
      end
    end
  end
end
