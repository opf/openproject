RSpec.describe Airbrake::PerformanceNotifier do
  let(:routes) { 'https://api.airbrake.io/api/v5/projects/1/routes-stats' }
  let(:queries) { 'https://api.airbrake.io/api/v5/projects/1/queries-stats' }
  let(:breakdowns) { 'https://api.airbrake.io/api/v5/projects/1/routes-breakdowns' }
  let(:queues) { 'https://api.airbrake.io/api/v5/projects/1/queues-stats' }

  before do
    stub_request(:put, routes).to_return(status: 200, body: '')
    stub_request(:put, queries).to_return(status: 200, body: '')
    stub_request(:put, breakdowns).to_return(status: 200, body: '')
    stub_request(:put, queues).to_return(status: 200, body: '')

    Airbrake::Config.instance = Airbrake::Config.new(
      project_id: 1,
      project_key: 'banana',
      performance_stats: true,
      performance_stats_flush_period: 0,
      query_stats: true,
      job_stats: true,
    )
  end

  describe "#notify" do
    it "sends full query" do
      subject.notify(
        Airbrake::Query.new(
          method: 'POST',
          route: '/foo',
          query: 'SELECT * FROM things',
          func: 'foo',
          file: 'foo.rb',
          line: 123,
          timing: 60000,
          time: Time.new(2018, 1, 1, 0, 49, 0, 0),
        ),
      )
      subject.close

      expect(
        a_request(:put, queries).with(body: %r|
          \A{"queries":\[{
            "method":"POST",
            "route":"/foo",
            "query":"SELECT\s\*\sFROM\sthings",
            "time":"2018-01-01T00:49:00\+00:00",
            "function":"foo",
            "file":"foo.rb",
            "line":123,
            "count":1,
            "sum":60000.0,
            "sumsq":3600000000.0,
            "tdigest":"AAAAAkA0AAAAAAAAAAAAAUdqYAAB"
          }\]}\z|x),
      ).to have_been_made
    end

    it "sends full request" do
      subject.notify(
        Airbrake::Request.new(
          method: 'POST',
          route: '/foo',
          status_code: 200,
          timing: 60000,
          time: Time.new(2018, 1, 1, 0, 49, 0, 0),
        ),
      )
      subject.close

      expect(
        a_request(:put, routes).with(body: %r|
          \A{"routes":\[{
            "method":"POST",
            "route":"/foo",
            "statusCode":200,
            "time":"2018-01-01T00:49:00\+00:00",
            "count":1,
            "sum":60000.0,
            "sumsq":3600000000.0,
            "tdigest":"AAAAAkA0AAAAAAAAAAAAAUdqYAAB"
          }\]}\z|x),
      ).to have_been_made
    end

    it "sends full performance breakdown" do
      subject.notify(
        Airbrake::PerformanceBreakdown.new(
          method: 'DELETE',
          route: '/routes-breakdowns',
          response_type: 'json',
          timing: 60000,
          time: Time.new(2018, 1, 1, 0, 49, 0, 0),
          groups: { db: 131, view: 421 },
        ),
      )
      subject.close

      expect(
        a_request(:put, breakdowns).with(body: %r|
          \A{"routes":\[{
            "method":"DELETE",
            "route":"/routes-breakdowns",
            "responseType":"json",
            "time":"2018-01-01T00:49:00\+00:00",
            "count":1,
            "sum":60000.0,
            "sumsq":3600000000.0,
            "tdigest":"AAAAAkA0AAAAAAAAAAAAAUdqYAAB",
            "groups":{
              "db":{
                "count":1,
                "sum":131.0,
                "sumsq":17161.0,
                "tdigest":"AAAAAkA0AAAAAAAAAAAAAUMDAAAB"
              },
              "view":{
                "count":1,
                "sum":421.0,
                "sumsq":177241.0,
                "tdigest":"AAAAAkA0AAAAAAAAAAAAAUPSgAAB"
              }
            }
        }\]}\z|x),
      ).to have_been_made
    end

    it "sends full queue" do
      subject.notify(
        Airbrake::Queue.new(
          queue: 'emails',
          error_count: 2,
          groups: { redis: 131, sql: 421 },
          timing: 60000,
          time: Time.new(2018, 1, 1, 0, 49, 0, 0),
        ),
      )
      subject.close

      expect(
        a_request(:put, queues).with(body: /
          \A{"queues":\[{
            "queue":"emails",
            "errorCount":2,
            "time":"2018-01-01T00:49:00\+00:00",
            "count":1,
            "sum":60000.0,
            "sumsq":3600000000.0,
            "tdigest":"AAAAAkA0AAAAAAAAAAAAAUdqYAAB",
            "groups":{
              "redis":{
                "count":1,
                "sum":131.0,
                "sumsq":17161.0,
                "tdigest":"AAAAAkA0AAAAAAAAAAAAAUMDAAAB"
              },
              "sql":{
                "count":1,
                "sum":421.0,
                "sumsq":177241.0,
                "tdigest":"AAAAAkA0AAAAAAAAAAAAAUPSgAAB"
              }
            }
        }\]}\z/x),
      ).to have_been_made
    end

    it "rounds time to the floor minute" do
      subject.notify(
        Airbrake::Request.new(
          method: 'GET',
          route: '/foo',
          status_code: 200,
          timing: 60000,
          time: Time.new(2018, 1, 1, 0, 0, 20, 0),
        ),
      )
      subject.close

      expect(
        a_request(:put, routes).with(body: /"time":"2018-01-01T00:00:00\+00:00"/),
      ).to have_been_made
    end

    it "increments routes with the same key" do
      subject.notify(
        Airbrake::Request.new(
          method: 'GET',
          route: '/foo',
          status_code: 200,
          timing: 213,
        ),
      )
      subject.notify(
        Airbrake::Request.new(
          method: 'GET',
          route: '/foo',
          status_code: 200,
          timing: 123,
        ),
      )
      subject.close

      expect(
        a_request(:put, routes).with(body: /"count":2/),
      ).to have_been_made
    end

    it "groups routes by time" do
      subject.notify(
        Airbrake::Request.new(
          method: 'GET',
          route: '/foo',
          status_code: 200,
          timing: 1000,
          time: Time.new(2018, 1, 1, 0, 0, 49, 0),
        ),
      )
      subject.notify(
        Airbrake::Request.new(
          method: 'GET',
          route: '/foo',
          status_code: 200,
          timing: 6000,
          time: Time.new(2018, 1, 1, 0, 1, 49, 0),
        ),
      )
      subject.close

      expect(
        a_request(:put, routes).with(
          body: %r|\A
            {"routes":\[
              {"method":"GET","route":"/foo","statusCode":200,
               "time":"2018-01-01T00:00:00\+00:00","count":1,"sum":1000.0,
               "sumsq":1000000.0,"tdigest":"AAAAAkA0AAAAAAAAAAAAAUR6AAAB"},
              {"method":"GET","route":"/foo","statusCode":200,
               "time":"2018-01-01T00:01:00\+00:00","count":1,"sum":6000.0,
               "sumsq":36000000.0,"tdigest":"AAAAAkA0AAAAAAAAAAAAAUW7gAAB"}\]}
          \z|x,
        ),
      ).to have_been_made
    end

    it "groups routes by route key" do
      subject.notify(
        Airbrake::Request.new(
          method: 'GET',
          route: '/foo',
          status_code: 200,
          timing: 60000,
          time: Time.new(2018, 1, 1, 0, 49, 0, 0),
        ),
      )
      subject.notify(
        Airbrake::Request.new(
          method: 'POST',
          route: '/foo',
          status_code: 200,
          timing: 60000,
          time: Time.new(2018, 1, 1, 0, 49, 0, 0),
        ),
      )
      subject.close

      expect(
        a_request(:put, routes).with(
          body: %r|\A
            {"routes":\[
              {"method":"GET","route":"/foo","statusCode":200,
               "time":"2018-01-01T00:49:00\+00:00","count":1,"sum":60000.0,
               "sumsq":3600000000.0,"tdigest":"AAAAAkA0AAAAAAAAAAAAAUdqYAAB"},
              {"method":"POST","route":"/foo","statusCode":200,
               "time":"2018-01-01T00:49:00\+00:00","count":1,"sum":60000.0,
               "sumsq":3600000000.0,"tdigest":"AAAAAkA0AAAAAAAAAAAAAUdqYAAB"}\]}
          \z|x,
        ),
      ).to have_been_made
    end

    it "groups performance breakdowns by route key" do
      subject.notify(
        Airbrake::PerformanceBreakdown.new(
          method: 'DELETE',
          route: '/routes-breakdowns',
          response_type: 'json',
          timing: 2000,
          time: Time.new(2018, 1, 1, 0, 0, 20, 0),
          groups: { db: 131, view: 421 },
        ),
      )
      subject.notify(
        Airbrake::PerformanceBreakdown.new(
          method: 'DELETE',
          route: '/routes-breakdowns',
          response_type: 'json',
          timing: 2000,
          time: Time.new(2018, 1, 1, 0, 0, 30, 0),
          groups: { db: 55, view: 11 },
        ),
      )
      subject.close

      expect(
        a_request(:put, breakdowns).with(body: %r|
          \A{"routes":\[{
            "method":"DELETE",
            "route":"/routes-breakdowns",
            "responseType":"json",
            "time":"2018-01-01T00:00:00\+00:00",
            "count":2,
            "sum":4000.0,
            "sumsq":8000000.0,
            "tdigest":"AAAAAkA0AAAAAAAAAAAAAUT6AAAC",
            "groups":{
              "db":{
                "count":2,
                "sum":186.0,
                "sumsq":20186.0,
                "tdigest":"AAAAAkA0AAAAAAAAAAAAAkJcAABCmAAAAQE="
              },
              "view":{
                "count":2,
                "sum":432.0,
                "sumsq":177362.0,
                "tdigest":"AAAAAkA0AAAAAAAAAAAAAkEwAABDzQAAAQE="
              }
            }
        }\]}\z|x),
      ).to have_been_made
    end

    it "groups queues by queue key" do
      subject.notify(
        Airbrake::Queue.new(
          queue: 'emails',
          error_count: 2,
          groups: { redis: 131, sql: 421 },
          timing: 60000,
          time: Time.new(2018, 1, 1, 0, 49, 0, 0),
        ),
      )
      subject.notify(
        Airbrake::Queue.new(
          queue: 'emails',
          error_count: 3,
          groups: { redis: 131, sql: 421 },
          timing: 60000,
          time: Time.new(2018, 1, 1, 0, 49, 0, 0),
        ),
      )
      subject.close

      expect(
        a_request(:put, queues).with(body: /
          \A{"queues":\[{
            "queue":"emails",
            "errorCount":5,
            "time":"2018-01-01T00:49:00\+00:00",
            "count":2,
            "sum":120000.0,
            "sumsq":7200000000.0,
            "tdigest":"AAAAAkA0AAAAAAAAAAAAAUdqYAAC",
            "groups":{
              "redis":{
                "count":2,
                "sum":262.0,
                "sumsq":34322.0,
                "tdigest":"AAAAAkA0AAAAAAAAAAAAAUMDAAAC"
              },
              "sql":{
                "count":2,
                "sum":842.0,
                "sumsq":354482.0,
                "tdigest":"AAAAAkA0AAAAAAAAAAAAAUPSgAAC"
              }
            }
        }\]}\z/x),
      ).to have_been_made
    end

    it "returns a promise" do
      promise = subject.notify(
        Airbrake::Request.new(
          method: 'GET',
          route: '/foo',
          status_code: 200,
          timing: 123,
        ),
      )
      subject.close

      expect(promise).to be_an(Airbrake::Promise)
      expect(promise.value).to eq('' => '')
    end

    it "checks performance stat configuration" do
      request = Airbrake::Request.new(
        method: 'GET', route: '/foo', status_code: 200, timing: 123,
      )
      expect(Airbrake::Config.instance).to receive(:check_performance_options)
        .with(request).and_return(Airbrake::Promise.new)
      subject.notify(request)
      subject.close
    end

    it "sends environment when it's specified" do
      Airbrake::Config.instance.merge(performance_stats: true, environment: 'test')

      subject.notify(
        Airbrake::Request.new(
          method: 'POST',
          route: '/foo',
          status_code: 200,
          timing: 123,
        ),
      )
      subject.close

      expect(
        a_request(:put, routes).with(
          body: /\A{"routes":\[.+\],"environment":"test"}\z/x,
        ),
      ).to have_been_made
    end

    context "when config is invalid" do
      before { Airbrake::Config.instance.merge(project_id: nil) }

      it "returns a rejected promise" do
        promise = subject.notify({})
        expect(promise).to be_rejected
      end
    end

    describe "payload grouping" do
      let(:flush_period) { 0.5 }

      it "groups payload by performance name and sends it separately" do
        Airbrake::Config.instance.merge(
          project_id: 1,
          project_key: 'banana',
          performance_stats: true,
          performance_stats_flush_period: flush_period,
        )

        subject.notify(
          Airbrake::Request.new(
            method: 'GET',
            route: '/foo',
            status_code: 200,
            timing: 123,
          ),
        )

        subject.notify(
          Airbrake::Query.new(
            method: 'POST',
            route: '/foo',
            query: 'SELECT * FROM things',
            timing: 123,
          ),
        )

        sleep(flush_period + 0.5)

        expect(a_request(:put, routes)).to have_been_made
        expect(a_request(:put, queries)).to have_been_made
      end
    end

    context "when an ignore filter was defined" do
      before { subject.add_filter(&:ignore!) }

      it "doesn't notify airbrake of requests" do
        subject.notify(
          Airbrake::Request.new(
            method: 'GET',
            route: '/foo',
            status_code: 200,
            timing: 1,
          ),
        )
        subject.close

        expect(a_request(:put, routes)).not_to have_been_made
      end

      it "doesn't notify airbrake of queries" do
        subject.notify(
          Airbrake::Query.new(
            method: 'POST',
            route: '/foo',
            query: 'SELECT * FROM things',
            timing: 1,
          ),
        )
        subject.close

        expect(a_request(:put, queries)).not_to have_been_made
      end

      it "returns a rejected promise" do
        promise = subject.notify(
          Airbrake::Query.new(
            method: 'POST',
            route: '/foo',
            query: 'SELECT * FROM things',
            timing: 1,
          ),
        )
        subject.close

        expect(promise.value).to eq(
          'error' => 'Airbrake::Query was ignored by a filter',
        )
      end
    end

    context "when a filter that modifies payload was defined" do
      before do
        subject.add_filter do |resource|
          resource.route = '[Filtered]'
        end
      end

      it "notifies airbrake with modified payload" do
        subject.notify(
          Airbrake::Query.new(
            method: 'POST',
            route: '/foo',
            query: 'SELECT * FROM things',
            timing: 123,
          ),
        )
        subject.close

        expect(
          a_request(:put, queries).with(
            body: /\A{"queries":\[{"method":"POST","route":"\[Filtered\]"/,
          ),
        ).to have_been_made
      end
    end

    context "when provided :timing is zero" do
      it "doesn't notify" do
        queue = Airbrake::Queue.new(queue: 'bananas', error_count: 0, timing: 0)
        subject.notify(queue)
        subject.close

        expect(a_request(:put, queues)).not_to have_been_made
      end

      it "returns a rejected promise" do
        queue = Airbrake::Queue.new(queue: 'bananas', error_count: 0, timing: 0)
        promise = subject.notify(queue)
        subject.close

        expect(promise.value).to eq('error' => ':timing cannot be zero')
      end
    end
  end

  describe "#notify_sync" do
    it "notifies synchronously" do
      retval = subject.notify_sync(
        Airbrake::Query.new(
          method: 'POST',
          route: '/foo',
          query: 'SELECT * FROM things',
          timing: 123,
        ),
      )

      expect(
        a_request(:put, queries).with(
          body: %r|\A{"queries":\[{"method":"POST","route":"/foo"|,
        ),
      ).to have_been_made
      expect(retval).to eq('' => '')
    end
  end

  describe "#close" do
    before do
      Airbrake::Config.instance.merge(performance_stats_flush_period: 0.1)
    end

    after do
      Airbrake::Config.instance.merge(performance_stats_flush_period: 0)
    end

    it "kills the background thread" do
      expect_any_instance_of(Thread).to receive(:kill).and_call_original
      subject.notify(
        Airbrake::Query.new(
          method: 'POST',
          route: '/foo',
          query: 'SELECT * FROM things',
          timing: 123,
        ),
      )
      subject.close
    end

    it "logs the exit message" do
      allow(Airbrake::Loggable.instance).to receive(:debug)
      expect(Airbrake::Loggable.instance).to receive(:debug).with(
        /performance notifier closed/,
      )
      subject.close
    end
  end

  describe "#delete_filter" do
    let(:filter) do
      Class.new do
        def call(resource); end
      end
    end

    before { subject.add_filter(filter.new) }

    it "deletes a filter" do
      subject.delete_filter(filter)
      subject.notify(
        Airbrake::Request.new(
          method: 'POST',
          route: '/foo',
          status_code: 200,
          timing: 123,
        ),
      )
      subject.close

      expect(a_request(:put, routes)).to have_been_made
    end
  end
end
