RSpec.describe Airbrake::NoticeNotifier do
  before do
    Airbrake::Config.instance = Airbrake::Config.new(
      project_id: 1,
      project_key: 'abc',
      logger: Logger.new('/dev/null'),
      performance_stats: true,
    )
  end

  describe "#new" do
    describe "default filter addition" do
      before { allow_any_instance_of(Airbrake::FilterChain).to receive(:add_filter) }

      it "appends the context filter" do
        expect_any_instance_of(Airbrake::FilterChain).to receive(:add_filter)
          .with(instance_of(Airbrake::Filters::ContextFilter))
        subject
      end

      it "appends the exception attributes filter" do
        expect_any_instance_of(Airbrake::FilterChain).to receive(:add_filter)
          .with(instance_of(Airbrake::Filters::ExceptionAttributesFilter))
        subject
      end
    end
  end

  describe "#notify" do
    let(:endpoint) { 'https://api.airbrake.io/api/v3/projects/1/notices' }

    let(:body) do
      {
        'id' => '00054414-b147-6ffa-85d6-1524d83362a6',
        'url' => 'http://localhost/locate/00054414-b147-6ffa-85d6-1524d83362a6',
      }.to_json
    end

    before { stub_request(:post, endpoint).to_return(status: 201, body: body) }

    it "returns a promise" do
      expect(subject.notify('ex')).to be_an(Airbrake::Promise)
      sleep 1
    end

    it "refines the notice object" do
      subject.add_filter { |n| n[:params] = { foo: 'bar' } }
      notice = subject.build_notice('ex')
      subject.notify(notice)
      expect(notice[:params]).to eq(foo: 'bar')
      sleep 1
    end

    context "when config is invalid" do
      before { Airbrake::Config.instance.merge(project_id: nil) }

      it "returns a rejected promise" do
        promise = subject.notify({})
        expect(promise).to be_rejected
      end
    end

    context "when a notice is not ignored" do
      it "yields the notice" do
        expect { |b| subject.notify('ex', &b) }
          .to yield_with_args(Airbrake::Notice)
        sleep 1
      end
    end

    context "when a notice is ignored via a filter" do
      before { subject.add_filter(&:ignore!) }

      it "yields the notice" do
        expect { |b| subject.notify('ex', &b) }
          .to yield_with_args(Airbrake::Notice)
      end

      it "returns a rejected promise" do
        value = subject.notify('ex').value
        expect(value['error']).to match(/was marked as ignored/)
      end
    end

    context "when a notice is ignored via an inline filter" do
      before { subject.add_filter { raise AirbrakeTestError } }

      it "doesn't invoke regular filters" do
        expect { subject.notify('ex', &:ignore!) }.not_to raise_error
      end
    end

    context "when async sender has workers" do
      it "sends an exception asynchronously" do
        expect_any_instance_of(Airbrake::AsyncSender).to receive(:send)
        subject.notify('foo', bingo: 'bango')
      end
    end

    context "when async sender doesn't have workers" do
      it "sends an exception synchronously" do
        expect_any_instance_of(Airbrake::AsyncSender)
          .to receive(:has_workers?).and_return(false)
        expect_any_instance_of(Airbrake::SyncSender).to receive(:send)
        subject.notify('foo', bingo: 'bango')
      end
    end

    context "when the provided environment is ignored" do
      before do
        Airbrake::Config.instance.merge(
          environment: 'test',
          ignore_environments: %w[test],
        )
      end

      it "doesn't send an notice" do
        expect_any_instance_of(Airbrake::AsyncSender).not_to receive(:send)
        subject.notify('foo', bingo: 'bango')
      end

      it "returns a rejected promise" do
        promise = subject.notify('foo', bingo: 'bango')
        expect(promise.value).to eq('error' => "current environment 'test' is ignored")
      end
    end
  end

  describe "#notify_sync" do
    let(:endpoint) { 'https://api.airbrake.io/api/v3/projects/1/notices' }

    let(:body) do
      {
        'id' => '00054414-b147-6ffa-85d6-1524d83362a6',
        'url' => 'http://localhost/locate/00054414-b147-6ffa-85d6-1524d83362a6',
      }
    end

    before { stub_request(:post, endpoint).to_return(status: 201, body: body.to_json) }

    it "returns a reponse hash" do
      expect(subject.notify_sync('ex')).to eq(body)
    end

    it "refines the notice object" do
      subject.add_filter { |n| n[:params] = { foo: 'bar' } }
      notice = subject.build_notice('ex')
      subject.notify_sync(notice)
      expect(notice[:params]).to eq(foo: 'bar')
    end

    it "sends an exception synchronously" do
      subject.notify_sync('foo', bingo: 'bango')
      expect(
        a_request(:post, endpoint).with(
          body: /"params":{.*"bingo":"bango".*}/,
        ),
      ).to have_been_made.once
    end

    context "when a notice is not ignored" do
      it "yields the notice" do
        expect { |b| subject.notify_sync('ex', &b) }
          .to yield_with_args(Airbrake::Notice)
      end
    end

    context "when a notice is ignored via a filter" do
      before { subject.add_filter(&:ignore!) }

      it "yields the notice" do
        expect { |b| subject.notify_sync('ex', &b) }
          .to yield_with_args(Airbrake::Notice)
      end

      it "returns an error hash" do
        response = subject.notify_sync('ex')
        expect(response['error']).to match(/was marked as ignored/)
      end
    end

    context "when a notice is ignored via an inline filter" do
      before { subject.add_filter { raise AirbrakeTestError } }

      it "doesn't invoke regular filters" do
        expect { subject.notify('ex', &:ignore!) }.not_to raise_error
      end
    end

    context "when the provided environment is ignored" do
      before do
        Airbrake::Config.instance.merge(
          environment: 'test', ignore_environments: %w[test],
        )
      end

      it "doesn't send an notice" do
        expect_any_instance_of(Airbrake::SyncSender).not_to receive(:send)
        subject.notify_sync('foo', bingo: 'bango')
      end

      it "returns an error hash" do
        expect(subject.notify_sync('foo'))
          .to eq('error' => "current environment 'test' is ignored")
      end
    end
  end

  describe "#add_filter" do
    context "given a block" do
      it "appends a new filter to the filter chain" do
        notifier = subject
        b = proc {}
        expect_any_instance_of(Airbrake::FilterChain)
          .to receive(:add_filter) { |*args| expect(args.last).to be(b) }
        notifier.add_filter(&b)
      end
    end

    context "given a class" do
      it "appends a new filter to the filter chain" do
        notifier = subject
        klass = Class.new
        expect_any_instance_of(Airbrake::FilterChain)
          .to receive(:add_filter).with(klass)
        notifier.add_filter(klass)
      end
    end
  end

  describe "#build_notice" do
    context "when given exception is another notice" do
      it "merges params with the notice" do
        notice = subject.build_notice('ex')
        other = subject.build_notice(notice, foo: 'bar')
        expect(other[:params]).to eq(foo: 'bar')
      end

      it "it returns the provided notice" do
        notice = subject.build_notice('ex')
        other = subject.build_notice(notice, foo: 'bar')
        expect(other).to eq(notice)
      end
    end

    context "when given exception is an Exception" do
      it "prevents mutation of passed-in params hash" do
        params = { immutable: true }
        notice = subject.build_notice('ex', params)
        notice[:params][:mutable] = true
        expect(params).to eq(immutable: true)
      end

      context "and also when it doesn't have own backtrace" do
        context "and when the generated backtrace consists only of library frames" do
          it "returns the full generated backtrace" do
            backtrace = [
              "/lib/airbrake-ruby/a.rb:84:in `build_notice'",
              "/lib/airbrake-ruby/b.rb:124:in `send_notice'",
            ]
            allow(Kernel).to receive(:caller).and_return(backtrace)

            notice = subject.build_notice(Exception.new)

            expect(notice[:errors].first[:backtrace]).to eq(
              [
                { file: '/lib/airbrake-ruby/a.rb', line: 84, function: 'build_notice' },
                { file: '/lib/airbrake-ruby/b.rb', line: 124, function: 'send_notice' },
              ],
            )
          end
        end

        context "and when the generated backtrace consists of mixed frames" do
          it "returns the filtered backtrace" do
            backtrace = [
              "/airbrake-ruby/lib/airbrake-ruby/a.rb:84:in `b'",
              "/airbrake-ruby/lib/foo/b.rb:84:in `build'",
              "/airbrake-ruby/lib/bar/c.rb:124:in `send'",
            ]
            allow(Kernel).to receive(:caller).and_return(backtrace)

            notice = subject.build_notice(Exception.new)

            expect(notice[:errors].first[:backtrace]).to eq(
              [
                { file: '/airbrake-ruby/lib/foo/b.rb', line: 84, function: 'build' },
                { file: '/airbrake-ruby/lib/bar/c.rb', line: 124, function: 'send' },
              ],
            )
          end
        end
      end
    end

    # TODO: this seems to be bugged. Fix later.
    context "when given exception is a Java exception", skip: true do
      before do
        expect(Airbrake::Backtrace).to receive(:java_exception?).and_return(true)
      end

      it "automatically generates the backtrace" do
        backtrace = [
          "org/jruby/RubyKernel.java:998:in `eval'",
          "/ruby/stdlib/irb/workspace.rb:87:in `evaluate'",
          "/ruby/stdlib/irb.rb:489:in `block in eval_input'",
        ]
        allow(Kernel).to receive(:caller).and_return(backtrace)

        notice = subject.build_notice(Exception.new)

        # rubocop:disable Layout/LineLength
        expect(notice[:errors].first[:backtrace]).to eq(
          [
            { file: 'org/jruby/RubyKernel.java', line: 998, function: 'eval' },
            { file: '/ruby/stdlib/irb/workspace.rb', line: 87, function: 'evaluate' },
            { file: '/ruby/stdlib/irb.rb:489', line: 489, function: 'block in eval_input' },
          ],
        )
        # rubocop:enable Layout/LineLength
      end
    end

    context "when async sender is closed" do
      before do
        expect_any_instance_of(Airbrake::AsyncSender)
          .to receive(:closed?).and_return(true)
      end

      it "raises error" do
        expect { subject.build_notice(Exception.new('oops')) }.to raise_error(
          Airbrake::Error,
          "Airbrake is closed; can't build exception: Exception: oops",
        )
      end
    end
  end

  describe "#close" do
    it "sends the close message to async sender" do
      expect_any_instance_of(Airbrake::AsyncSender).to receive(:close)
      subject.close
    end
  end

  describe "#configured?" do
    it { is_expected.to be_configured }
  end

  describe "#merge_context" do
    it "merges the provided context with the notice object" do
      expect_any_instance_of(Hash).to receive(:merge!).with(apples: 'oranges')
      subject.merge_context(apples: 'oranges')
    end
  end
end
