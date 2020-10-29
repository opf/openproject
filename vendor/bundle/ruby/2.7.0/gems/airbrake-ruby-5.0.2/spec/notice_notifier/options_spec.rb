RSpec.describe Airbrake::NoticeNotifier do
  let(:project_id) { 105138 }
  let(:project_key) { 'fd04e13d806a90f96614ad8e529b2822' }
  let(:localhost) { 'http://localhost:8080' }

  let(:endpoint) do
    "https://api.airbrake.io/api/v3/projects/#{project_id}/notices"
  end

  let(:params) { {} }
  let(:ex) { AirbrakeTestError.new }

  before do
    stub_request(:post, endpoint).to_return(status: 201, body: '{}')

    Airbrake::Config.instance = Airbrake::Config.new(
      project_id: project_id,
      project_key: project_key,
    )
  end

  describe "options" do
    describe ":host" do
      context "when custom" do
        shared_examples 'endpoint' do |host, endpoint, title|
          before { Airbrake::Config.instance.merge(host: host) }

          example(title) do
            stub_request(:post, endpoint).to_return(status: 201, body: '{}')
            subject.notify_sync(ex)

            expect(a_request(:post, endpoint)).to have_been_made.once
          end
        end

        path = '/api/v3/projects/105138/notices'

        context "given a full host" do
          include_examples('endpoint', localhost = 'http://localhost:8080',
                           URI.join(localhost, path),
                           "sends notices to the specified host's endpoint")
        end

        context "given a full host" do
          include_examples('endpoint', localhost = 'http://localhost',
                           URI.join(localhost, path),
                           "assumes port 80 by default")
        end

        context "given a host without scheme" do
          include_examples 'endpoint', localhost = 'localhost:8080',
                           URI.join("https://#{localhost}", path),
                           "assumes https by default"
        end

        context "given only hostname" do
          include_examples 'endpoint', localhost = 'localhost',
                           URI.join("https://#{localhost}", path),
                           "assumes https and port 80 by default"
        end
      end
    end

    describe ":root_directory" do
      before do
        subject.add_filter(
          Airbrake::Filters::RootDirectoryFilter.new('/home/kyrylo/code'),
        )
      end

      it "filters out frames" do
        subject.notify_sync(ex)

        expect(
          a_request(:post, endpoint)
          .with(body: %r|{"file":"/PROJECT_ROOT/airbrake/ruby/spec/airbrake_spec.+|),
        ).to have_been_made.once
      end

      context "when present and is a" do
        shared_examples 'root directory' do |dir|
          before { Airbrake::Config.instance.merge(root_directory: dir) }

          it "being included into the notice's payload" do
            subject.notify_sync(ex)
            expect(
              a_request(:post, endpoint)
              .with(body: %r{"rootDirectory":"/bingo/bango"}),
            ).to have_been_made.once
          end
        end

        context "String" do
          include_examples 'root directory', '/bingo/bango'
        end

        context "Pathname" do
          include_examples 'root directory', Pathname.new('/bingo/bango')
        end
      end
    end

    describe ":proxy" do
      let(:proxy) do
        WEBrick::HTTPServer.new(
          Port: 0,
          Logger: WEBrick::Log.new('/dev/null'),
          AccessLog: [],
        )
      end

      let(:requests) { Queue.new }

      let(:proxy_params) do
        { host: 'localhost',
          port: proxy.config[:Port],
          user: 'user',
          password: 'password' }
      end

      before do
        Airbrake::Config.instance.merge(
          proxy: proxy_params,
          host: "http://localhost:#{proxy.config[:Port]}",
        )

        proxy.mount_proc '/' do |req, res|
          requests << req
          res.status = 201
          res.body = "OK\n"
        end

        Thread.new { proxy.start }
      end

      after { proxy.stop }

      it "is being used if configured" do
        if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new("2.6.0")
          skip(
            "We use Webmock 2, which doesn't support Ruby 2.6+. It's " \
            "safe to run this test on 2.6+ once we upgrade to Webmock 3.5+",
          )
        end
        subject.notify_sync(ex)

        proxied_request = requests.pop(true)

        expect(proxied_request.header['proxy-authorization'].first)
          .to eq('Basic dXNlcjpwYXNzd29yZA==')

        # rubocop:disable Layout/LineLength
        expect(proxied_request.request_line)
          .to eq("POST http://localhost:#{proxy.config[:Port]}/api/v3/projects/105138/notices HTTP/1.1\r\n")
        # rubocop:enable Layout/LineLength
      end
    end

    describe ":environment" do
      context "when present" do
        before { Airbrake::Config.instance.merge(environment: :production) }

        it "being included into the notice's payload" do
          subject.notify_sync(ex)
          expect(
            a_request(:post, endpoint)
            .with(body: /"context":{.*"environment":"production".*}/),
          ).to have_been_made.once
        end
      end
    end

    describe ":ignore_environments" do
      shared_examples 'sent notice' do |params|
        before { Airbrake::Config.instance.merge(params) }

        it "sends a notice" do
          subject.notify_sync(ex)
          expect(a_request(:post, endpoint)).to have_been_made
        end
      end

      shared_examples 'ignored notice' do |params|
        before { Airbrake::Config.instance.merge(params) }

        it "ignores exceptions occurring in envs that were not configured" do
          subject.notify_sync(ex)
          expect(a_request(:post, endpoint)).not_to have_been_made
        end
      end

      context "when env is set and ignore_environments doesn't mention it" do
        params = {
          environment: :development,
          ignore_environments: [:production],
        }

        include_examples 'sent notice', params
      end

      context "when the current env and notify envs are the same" do
        params = {
          environment: :development,
          ignore_environments: %i[production development],
        }

        include_examples 'ignored notice', params

        it "returns early and doesn't try to parse the given exception" do
          expect(Airbrake::Notice).not_to receive(:new)
          expect(subject.notify_sync(ex))
            .to eq('error' => "current environment 'development' is ignored")
          expect(a_request(:post, endpoint)).not_to have_been_made
        end
      end

      context "when the current env is not set and notify envs are present" do
        params = { ignore_environments: %i[production development] }

        include_examples 'sent notice', params
      end

      context "when the current env is set and notify envs aren't" do
        include_examples 'sent notice', environment: :development
      end

      context "when ignore_environments specifies a Regexp pattern" do
        params = {
          environment: :testing,
          ignore_environments: ['staging', /test.+/],
        }

        include_examples 'ignored notice', params
      end
    end

    describe ":blocklist_keys" do
      # Fixes https://github.com/airbrake/airbrake-ruby/issues/276
      context "when specified along with :allowlist_keys" do
        context "and when context payload is present" do
          before do
            Airbrake::Config.instance.merge(
              blocklist_keys: %i[password password_confirmation],
              allowlist_keys: [:email, /user/i, 'account_id'],
            )
          end

          it "sends a notice" do
            notice = subject.build_notice(ex)
            notice[:context][:headers] = 'banana'
            subject.notify_sync(notice)

            expect(a_request(:post, endpoint)).to have_been_made
          end
        end
      end
    end
  end
end
