RSpec.describe Airbrake::RemoteSettings do
  let(:project_id) { 123 }
  let(:host) { 'https://v1-production-notifier-configs.s3.amazonaws.com' }

  let(:endpoint) do
    "#{host}/2020-06-18/config/#{project_id}/config.json"
  end

  let(:body) do
    {
      'poll_sec' => 1,
      'settings' => [
        {
          'name' => 'apm',
          'enabled' => false,
        },
        {
          'name' => 'errors',
          'enabled' => true,
        },
      ],
    }
  end

  let(:config_path) { described_class::CONFIG_DUMP_PATH }
  let(:config_dir) { File.dirname(config_path) }

  let!(:stub) do
    stub_request(:get, Regexp.new(endpoint))
      .to_return(status: 200, body: body.to_json)
  end

  before do
    # Do not create config dumps on disk.
    allow(Dir).to receive(:mkdir).with(config_dir)
    allow(File).to receive(:write).with(config_path, anything)
  end

  describe ".poll" do
    describe "config loading" do
      let(:settings_data) { described_class::SettingsData.new(project_id, body) }

      before do
        allow(File).to receive(:exist?).with(config_path).and_return(true)
        allow(File).to receive(:read).with(config_path).and_return(body.to_json)

        allow(described_class::SettingsData).to receive(:new).and_return(settings_data)
      end

      it "loads the config from disk" do
        expect(File).to receive(:read).with(config_path)
        expect(settings_data).to receive(:merge!).with(body).twice

        remote_settings = described_class.poll(project_id, host) {}
        sleep(0.2)
        remote_settings.stop_polling

        expect(stub).to have_been_requested.once
      end

      it "yields the config to the block twice" do
        block = proc {}
        expect(block).to receive(:call).twice

        remote_settings = described_class.poll(project_id, host, &block)
        sleep(0.2)
        remote_settings.stop_polling

        expect(stub).to have_been_requested.once
      end

      context "when config loading fails" do
        it "logs an error" do
          expect(File).to receive(:read).and_raise(StandardError)
          expect(Airbrake::Loggable.instance).to receive(:error).with(
            '**Airbrake: config loading failed: StandardError',
          )

          remote_settings = described_class.poll(project_id, host) {}
          sleep(0.2)
          remote_settings.stop_polling

          expect(stub).to have_been_requested.once
        end
      end
    end

    context "when no errors are raised" do
      it "makes a request to AWS S3" do
        remote_settings = described_class.poll(project_id, host) {}
        sleep(0.1)
        remote_settings.stop_polling

        expect(stub).to have_been_requested.at_least_once
      end

      it "sends params about the environment with the request" do
        remote_settings = described_class.poll(project_id, host) {}
        sleep(0.1)
        remote_settings.stop_polling

        stub_with_query_params = stub.with(
          query: URI.decode_www_form(described_class::QUERY_PARAMS).to_h,
        )
        expect(stub_with_query_params).to have_been_requested.at_least_once
      end

      it "fetches remote settings" do
        settings = nil
        remote_settings = described_class.poll(project_id, host) do |data|
          settings = data
        end
        sleep(0.1)
        remote_settings.stop_polling

        expect(settings.error_notifications?).to eq(true)
        expect(settings.performance_stats?).to eq(false)
        expect(settings.interval).to eq(1)
      end
    end

    context "when an error is raised while making a HTTP request" do
      before do
        allow(Net::HTTP).to receive(:get).and_raise(StandardError)
      end

      it "doesn't fetch remote settings" do
        settings = nil
        remote_settings = described_class.poll(project_id, host) do |data|
          settings = data
        end
        sleep(0.1)
        remote_settings.stop_polling

        expect(stub).not_to have_been_requested
        expect(settings.interval).to eq(600)
      end
    end

    context "when an error is raised while parsing returned JSON" do
      before do
        allow(JSON).to receive(:parse).and_raise(JSON::ParserError)
      end

      it "doesn't update settings data" do
        settings = nil
        remote_settings = described_class.poll(project_id, host) do |data|
          settings = data
        end
        sleep(0.1)
        remote_settings.stop_polling

        expect(stub).to have_been_requested.once
        expect(settings.interval).to eq(600)
      end
    end

    context "when API returns an XML response" do
      let!(:stub) do
        stub_request(:get, Regexp.new(endpoint))
          .to_return(status: 200, body: '<?xml ...')
      end

      it "doesn't update settings data" do
        settings = nil
        remote_settings = described_class.poll(project_id, host) do |data|
          settings = data
        end
        sleep(0.1)
        remote_settings.stop_polling

        expect(stub).to have_been_requested.once
        expect(settings.interval).to eq(600)
      end
    end

    context "when a config route is specified in the returned data" do
      let(:new_config_route) do
        '213/config/111/config.json'
      end

      let(:body) do
        { 'config_route' => new_config_route, 'poll_sec' => 0.1 }
      end

      let!(:new_stub) do
        stub_request(:get, Regexp.new(new_config_route))
          .to_return(status: 200, body: body.to_json)
      end

      it "makes the next request to the specified config route" do
        remote_settings = described_class.poll(project_id, host) {}
        sleep(0.2)

        remote_settings.stop_polling

        expect(stub).to have_been_requested.once
        expect(new_stub).to have_been_requested.once
      end
    end
  end

  describe "#stop_polling" do
    it "dumps config data to disk" do
      expect(Dir).to receive(:mkdir).with(config_dir)
      expect(File).to receive(:write).with(config_path, body.to_json)

      remote_settings = described_class.poll(project_id, host) {}
      sleep(0.2)
      remote_settings.stop_polling

      expect(stub).to have_been_requested.once
    end

    context "when config dumping fails" do
      it "logs an error" do
        expect(File).to receive(:write).and_raise(StandardError)
        expect(Airbrake::Loggable.instance).to receive(:error).with(
          '**Airbrake: config dumping failed: StandardError',
        )

        remote_settings = described_class.poll(project_id, host) {}
        sleep(0.2)
        remote_settings.stop_polling

        expect(stub).to have_been_requested.once
      end
    end
  end
end
