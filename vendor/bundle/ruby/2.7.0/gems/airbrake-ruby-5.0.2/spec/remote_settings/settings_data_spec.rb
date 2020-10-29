RSpec.describe Airbrake::RemoteSettings::SettingsData do
  let(:project_id) { 123 }

  describe "#merge!" do
    it "returns self" do
      settings_data = described_class.new(project_id, {})
      expect(settings_data.merge!({})).to eql(settings_data)
    end

    it "merges the given hash with the data" do
      settings_data = described_class.new(project_id, {})
      settings_data.merge!('poll_sec' => 123, 'config_route' => 'abc')

      expect(settings_data.interval).to eq(123)
      expect(settings_data.config_route(''))
        .to eq('/abc')
    end
  end

  describe "#interval" do
    context "when given data has zero interval" do
      let(:data) do
        { 'poll_sec' => 0 }
      end

      it "returns the default interval" do
        expect(described_class.new(project_id, data).interval).to eq(600)
      end
    end

    context "when given data has negative interval" do
      let(:data) do
        { 'poll_sec' => -1 }
      end

      it "returns the default interval" do
        expect(described_class.new(project_id, data).interval).to eq(600)
      end
    end

    context "when given data has nil interval" do
      let(:data) do
        { 'poll_sec' => nil }
      end

      it "returns the default interval" do
        expect(described_class.new(project_id, data).interval).to eq(600)
      end
    end

    context "when given data has a positive interval" do
      let(:data) do
        { 'poll_sec' => 123 }
      end

      it "returns the interval from data" do
        expect(described_class.new(project_id, data).interval).to eq(123)
      end
    end
  end

  describe "#config_route" do
    let(:host) { 'http://example.com/' }

    context "when remote config specifies a config route" do
      let(:data) do
        { 'config_route' => '123/cfg/321/cfg.json' }
      end

      it "returns the config route with the provided location" do
        expect(described_class.new(project_id, data).config_route(host)).to eq(
          'http://example.com/123/cfg/321/cfg.json',
        )
      end
    end

    context "when remote config DOES NOT specify a config route" do
      it "returns the config route with the default location" do
        expect(described_class.new(project_id, {}).config_route(host)).to eq(
          "http://example.com/2020-06-18/config/#{project_id}/config.json",
        )
      end
    end

    context "when a config route is specified but is set to nil" do
      let(:data) do
        { 'config_route' => nil }
      end

      it "returns the config route with the default location" do
        expect(described_class.new(project_id, data).config_route(host)).to eq(
          "http://example.com/2020-06-18/config/#{project_id}/config.json",
        )
      end
    end

    context "when a config route is specified but is set to an empty string" do
      let(:data) do
        { 'config_route' => '' }
      end

      it "returns the route with the default instead" do
        expect(described_class.new(project_id, data).config_route(host)).to eq(
          "http://example.com/2020-06-18/config/#{project_id}/config.json",
        )
      end
    end
  end

  describe "#error_notifications?" do
    context "when the 'errors' setting is present" do
      context "and when it is enabled" do
        let(:data) do
          {
            'settings' => [
              {
                'name' => 'errors',
                'enabled' => true,
              },
            ],
          }
        end

        it "returns true" do
          expect(described_class.new(project_id, data).error_notifications?)
            .to eq(true)
        end
      end

      context "and when it is disabled" do
        let(:data) do
          {
            'settings' => [
              {
                'name' => 'errors',
                'enabled' => false,
              },
            ],
          }
        end

        it "returns false" do
          expect(described_class.new(project_id, data).error_notifications?)
            .to eq(false)
        end
      end
    end

    context "when the 'errors' setting is missing" do
      let(:data) do
        { 'settings' => [] }
      end

      it "returns true" do
        expect(described_class.new(project_id, data).error_notifications?)
          .to eq(true)
      end
    end
  end

  describe "#performance_stats?" do
    context "when the 'apm' setting is present" do
      context "and when it is enabled" do
        let(:data) do
          {
            'settings' => [
              {
                'name' => 'apm',
                'enabled' => true,
              },
            ],
          }
        end

        it "returns true" do
          expect(described_class.new(project_id, data).performance_stats?)
            .to eq(true)
        end
      end

      context "and when it is disabled" do
        let(:data) do
          {
            'settings' => [
              {
                'name' => 'apm',
                'enabled' => false,
              },
            ],
          }
        end

        it "returns false" do
          expect(described_class.new(project_id, data).performance_stats?)
            .to eq(false)
        end
      end
    end

    context "when the 'apm' setting is missing" do
      let(:data) do
        { 'settings' => [] }
      end

      it "returns true" do
        expect(described_class.new(project_id, data).performance_stats?)
          .to eq(true)
      end
    end
  end

  describe "#error_host" do
    context "when the 'errors' setting is present" do
      context "and when 'endpoint' is specified" do
        let(:endpoint) { 'https://api.example.com/' }

        let(:data) do
          {
            'settings' => [
              {
                'name' => 'errors',
                'enabled' => true,
                'endpoint' => endpoint,
              },
            ],
          }
        end

        it "returns the endpoint" do
          expect(described_class.new(project_id, data).error_host).to eq(endpoint)
        end
      end

      context "and when an endpoint is NOT specified" do
        let(:data) do
          {
            'settings' => [
              {
                'name' => 'errors',
                'enabled' => true,
              },
            ],
          }
        end

        it "returns nil" do
          expect(described_class.new(project_id, data).error_host).to be_nil
        end
      end
    end

    context "when the 'errors' setting is missing" do
      let(:data) do
        { 'settings' => [] }
      end

      it "returns nil" do
        expect(described_class.new(project_id, data).error_host).to be_nil
      end
    end
  end

  describe "#apm_host" do
    context "when the 'apm' setting is present" do
      context "and when 'endpoint' is specified" do
        let(:endpoint) { 'https://api.example.com/' }

        let(:data) do
          {
            'settings' => [
              {
                'name' => 'apm',
                'enabled' => true,
                'endpoint' => endpoint,
              },
            ],
          }
        end

        it "returns the endpoint" do
          expect(described_class.new(project_id, data).apm_host).to eq(endpoint)
        end
      end

      context "and when an endpoint is NOT specified" do
        let(:data) do
          {
            'settings' => [
              {
                'name' => 'apm',
                'enabled' => true,
              },
            ],
          }
        end

        it "returns nil" do
          expect(described_class.new(project_id, data).apm_host).to be_nil
        end
      end
    end

    context "when the 'apm' setting is missing" do
      let(:data) do
        { 'settings' => [] }
      end

      it "returns nil" do
        expect(described_class.new(project_id, data).apm_host).to be_nil
      end
    end
  end

  describe "#to_h" do
    let(:data) do
      {
        'poll_sec' => 123,
        'settings' => [
          {
            'name' => 'apm',
            'enabled' => false,
          },
        ],
      }
    end

    subject { described_class.new(project_id, data) }

    it "returns a hash representation of settings" do
      expect(described_class.new(project_id, data).to_h).to eq(data)
    end

    it "doesn't allow mutation of the original data object" do
      hash = subject.to_h
      hash['poll_sec'] = 0

      expect(subject.to_h).to eq(
        'poll_sec' => 123,
        'settings' => [
          {
            'name' => 'apm',
            'enabled' => false,
          },
        ],
      )
    end
  end
end
