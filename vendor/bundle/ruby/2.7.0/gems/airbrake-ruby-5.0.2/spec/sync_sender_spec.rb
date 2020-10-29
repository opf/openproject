RSpec.describe Airbrake::SyncSender do
  before do
    Airbrake::Config.instance = Airbrake::Config.new(
      project_id: 1, project_key: 'banana',
    )
  end

  describe "#send" do
    let(:promise) { Airbrake::Promise.new }

    let(:notice) { Airbrake::Notice.new(AirbrakeTestError.new) }
    let(:endpoint) { 'https://api.airbrake.io/api/v3/projects/1/notices' }

    before { stub_request(:post, endpoint).to_return(body: '{}') }

    it "sets the Content-Type header to JSON" do
      subject.send({}, promise)
      expect(
        a_request(:post, endpoint).with(
          headers: { 'Content-Type' => 'application/json' },
        ),
      ).to have_been_made.once
    end

    it "sets the User-Agent header to the notifier slug" do
      subject.send({}, promise)
      expect(
        a_request(:post, endpoint).with(
          headers: {
            'User-Agent' => %r{
              airbrake-ruby/\d+\.\d+\.\d+(\.rc\.\d+)?\sRuby/\d+\.\d+\.\d+
            }x,
          },
        ),
      ).to have_been_made.once
    end

    it "sets the Authorization header to the project key" do
      subject.send({}, promise)
      expect(
        a_request(:post, endpoint).with(
          headers: { 'Authorization' => 'Bearer banana' },
        ),
      ).to have_been_made.once
    end

    it "catches exceptions raised while sending" do
      https = double("foo")
      allow(subject).to receive(:build_https).and_return(https)
      allow(https).to receive(:request).and_raise(StandardError.new('foo'))
      expect(Airbrake::Loggable.instance).to receive(:error).with(
        /HTTP error: foo/,
      )
      expect(subject.send({}, promise)).to be_an(Airbrake::Promise)
      expect(promise.value).to eq('error' => '**Airbrake: HTTP error: foo')
    end

    context "when request body is nil" do
      it "doesn't send data" do
        expect_any_instance_of(Airbrake::Truncator)
          .to receive(:reduce_max_size).and_return(0)

        encoded = Base64.encode64("\xD3\xE6\xBC\x9D\xBA").encode!('ASCII-8BIT')
        bad_string = Base64.decode64(encoded)

        ex = AirbrakeTestError.new
        backtrace = []
        10.times { backtrace << "bin/rails:3:in `<#{bad_string}>'" }
        ex.set_backtrace(backtrace)

        notice = Airbrake::Notice.new(ex)

        expect(Airbrake::Loggable.instance).to receive(:error).with(
          /data was not sent/,
        )
        expect(Airbrake::Loggable.instance).to receive(:error).with(
          /truncation failed/,
        )
        expect(subject.send(notice, promise)).to be_an(Airbrake::Promise)
        expect(promise.value)
          .to match('error' => '**Airbrake: data was not sent because of missing body')
      end
    end

    context "when IP is rate limited" do
      let(:endpoint) { %r{https://api.airbrake.io/api/v3/projects/1/notices} }

      before do
        stub_request(:post, endpoint).to_return(
          status: 429,
          body: '{"message":"IP is rate limited"}',
          headers: { 'X-RateLimit-Delay' => '1' },
        )
      end

      it "returns error" do
        p1 = Airbrake::Promise.new
        subject.send({}, p1)
        expect(p1.value).to match('error' => '**Airbrake: IP is rate limited')

        p2 = Airbrake::Promise.new
        subject.send({}, p2)
        expect(p2.value).to match('error' => '**Airbrake: IP is rate limited')

        # Wait for X-RateLimit-Delay and then make a new request to make sure p2
        # was ignored (no request made for it).
        sleep 1

        p3 = Airbrake::Promise.new
        subject.send({}, p3)
        expect(p3.value).to match('error' => '**Airbrake: IP is rate limited')

        expect(a_request(:post, endpoint)).to have_been_made.twice
      end
    end

    context "when the provided method is :put" do
      before { stub_request(:put, endpoint).to_return(status: 200, body: '') }

      it "PUTs the request" do
        sender = described_class.new(:put)
        sender.send({}, promise)
        expect(a_request(:put, endpoint)).to have_been_made
      end
    end

    context "when the provided method is :post" do
      it "POSTs the request" do
        sender = described_class.new(:post)
        sender.send({}, promise)
        expect(a_request(:post, endpoint)).to have_been_made
      end
    end
  end
end
