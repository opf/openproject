RSpec.describe Airbrake::Notice do
  let(:notice) { described_class.new(AirbrakeTestError.new, bingo: '1') }

  describe "#to_json" do
    context "app_version" do
      context "when missing" do
        before { Airbrake::Config.instance.merge(app_version: nil) }

        it "doesn't include app_version" do
          expect(notice.to_json).not_to match(/"context":{"version":"1.2.3"/)
        end
      end

      context "when present" do
        let(:notice) { described_class.new(AirbrakeTestError.new) }

        before do
          Airbrake::Config.instance.merge(
            app_version: "1.2.3",
            root_directory: "/one/two",
          )
        end

        it "includes app_version" do
          expect(notice.to_json).to match(/"context":{"version":"1.2.3"/)
        end

        it "includes root_directory" do
          expect(notice.to_json).to match(%r{"rootDirectory":"/one/two"})
        end
      end
    end

    context "when versions is empty" do
      it "doesn't set the 'versions' payload" do
        expect(notice.to_json).not_to match(
          /"context":{"versions":{"dep":"1.2.3"}}/,
        )
      end
    end

    context "when versions is not empty" do
      it "sets the 'versions' payload" do
        notice[:context][:versions] = { 'dep' => '1.2.3' }
        expect(notice.to_json).to match(
          /"context":{.*"versions":{"dep":"1.2.3"}.*}/,
        )
      end
    end

    context "truncation" do
      shared_examples 'payloads' do |size, msg|
        it msg do
          ex = AirbrakeTestError.new

          backtrace = []
          size.times { backtrace << "bin/rails:3:in `<main>'" }
          ex.set_backtrace(backtrace)

          notice = described_class.new(ex)

          expect(notice.to_json.bytesize).to be < 64000
        end
      end

      max_msg = 'truncates to the max allowed size'

      context "with an extremely huge payload" do
        include_examples 'payloads', 200_000, max_msg
      end

      context "with a big payload" do
        include_examples 'payloads', 50_000, max_msg
      end

      small_msg = "doesn't truncate it"

      context "with a small payload" do
        include_examples 'payloads', 1000, small_msg
      end

      context "with a tiny payload" do
        include_examples 'payloads', 300, small_msg
      end

      context "when truncation failed" do
        it "returns nil" do
          expect_any_instance_of(Airbrake::Truncator)
            .to receive(:reduce_max_size).and_return(0)

          encoded = Base64.encode64("\xD3\xE6\xBC\x9D\xBA").encode!('ASCII-8BIT')
          bad_string = Base64.decode64(encoded)

          ex = AirbrakeTestError.new

          backtrace = []
          10.times { backtrace << "bin/rails:3:in `<#{bad_string}>'" }
          ex.set_backtrace(backtrace)

          notice = described_class.new(ex)
          expect(notice.to_json).to be_nil
        end
      end

      describe "object replacement with its string version" do
        let(:klass) { Class.new {} }
        let(:ex) { AirbrakeTestError.new }
        let(:params) { { bingo: [Object.new, klass.new] } }
        let(:notice) { described_class.new(ex, params) }

        before do
          backtrace = []
          backtrace_size.times { backtrace << "bin/rails:3:in `<main>'" }
          ex.set_backtrace(backtrace)
        end

        context "with payload within the limits" do
          let(:backtrace_size) { 1000 }

          it "doesn't happen" do
            expect(notice.to_json)
              .to match(/bingo":\["#<Object:.+>","#<#<Class:.+>:.+>"/)
          end
        end

        context "with payload bigger than the limit" do
          context "with payload within the limits" do
            let(:backtrace_size) { 50_000 }

            it "happens" do
              expect(notice.to_json)
                .to match(/bingo":\[".+Object.+",".+Class.+"/)
            end
          end
        end
      end
    end

    context "given a closed IO object" do
      context "and when it is not monkey-patched by ActiveSupport" do
        it "is not getting truncated" do
          notice[:params] = { obj: IO.new(0).tap(&:close) }
          expect(notice.to_json).to match(/"obj":"#<IO:0x.+>"/)
        end
      end

      context "and when it is monkey-patched by ActiveSupport" do
        # Instances of this class contain a closed IO object assigned to an
        # instance variable. Normally, the JSON gem, which we depend on can
        # parse closed IO objects. However, because ActiveSupport monkey-patches
        # #to_json and calls #to_a on them, they raise IOError when we try to
        # serialize them.
        #
        # @see https://goo.gl/0A3xNC
        class ObjectWithIoIvars
          def initialize
            @bongo = Tempfile.new('bongo').tap(&:close)
          end

          # @raise [NotImplementedError] when inside a Rails environment
          def to_json(*)
            raise NotImplementedError
          end
        end

        # @see ObjectWithIoIvars
        class ObjectWithNestedIoIvars
          def initialize
            @bish = ObjectWithIoIvars.new
          end

          # @see ObjectWithIoIvars#to_json
          def to_json(*)
            raise NotImplementedError
          end
        end

        context "and also when it's a closed Tempfile" do
          it "doesn't fail" do
            notice[:params] = { obj: Tempfile.new('bongo').tap(&:close) }
            expect(notice.to_json).to match(/"obj":"#<(Temp)?file:0x.+>"/i)
          end
        end

        context "and also when it's an IO ivar" do
          it "doesn't fail" do
            notice[:params] = { obj: ObjectWithIoIvars.new }
            expect(notice.to_json).to match(/"obj":".+ObjectWithIoIvars.+"/)
          end

          context "and when it's deeply nested inside a hash" do
            it "doesn't fail" do
              notice[:params] = { a: { b: { c: ObjectWithIoIvars.new } } }
              expect(notice.to_json).to match(
                /"params":{"a":{"b":{"c":".+ObjectWithIoIvars.+"}}.*}/,
              )
            end
          end

          context "and when it's deeply nested inside an array" do
            it "doesn't fail" do
              notice[:params] = { a: [[ObjectWithIoIvars.new]] }
              expect(notice.to_json).to match(
                /"params":{"a":\[\[".+ObjectWithIoIvars.+"\]\].*}/,
              )
            end
          end
        end

        context "and also when it's a non-IO ivar, which contains an IO ivar itself" do
          it "doesn't fail" do
            notice[:params] = { obj: ObjectWithNestedIoIvars.new }
            expect(notice.to_json).to match(/"obj":".+ObjectWithNested.+"/)
          end
        end
      end
    end

    it "overwrites the 'notifier' payload with the default values" do
      notice[:notifier] = { name: 'bingo', bango: 'bongo' }

      expect(notice.to_json)
        .to match(/"notifier":{"name":"airbrake-ruby","version":".+","url":".+"}/)
    end

    it "always contains context/hostname" do
      expect(notice.to_json)
        .to match(/"context":{.*"hostname":".+".*}/)
    end

    it "defaults to the error severity" do
      expect(notice.to_json).to match(/"context":{.*"severity":"error".*}/)
    end

    it "always contains environment/program_name" do
      expect(notice.to_json)
        .to match(%r|"environment":{"program_name":.+/rspec.*|)
    end

    it "contains errors" do
      expect(notice.to_json)
        .to match(/"errors":\[{"type":"AirbrakeTestError","message":"App crash/)
    end

    it "contains a backtrace" do
      expect(notice.to_json)
        .to match(%r|"backtrace":\[{"file":"/home/.+/spec/spec_helper.rb"|)
    end

    it "contains params" do
      expect(notice.to_json).to match(/"params":{"bingo":"1"}/)
    end
  end

  describe "#[]" do
    it "accesses payload" do
      expect(notice[:params]).to eq(bingo: '1')
    end

    it "raises error if notice is ignored" do
      notice.ignore!
      expect { notice[:params] }
        .to raise_error(Airbrake::Error, 'cannot access ignored Airbrake::Notice')
    end
  end

  describe "#[]=" do
    it "sets a payload value" do
      hash = { bingo: 'bango' }
      notice[:params] = hash
      expect(notice[:params]).to eq(hash)
    end

    it "raises error if notice is ignored" do
      notice.ignore!
      expect { notice[:params] = {} }
        .to raise_error(Airbrake::Error, 'cannot access ignored Airbrake::Notice')
    end

    it "raises error when trying to assign unrecognized key" do
      expect { notice[:bingo] = 1 }
        .to raise_error(Airbrake::Error, /:bingo is not recognized among/)
    end

    it "raises when setting non-hash objects as the value" do
      expect { notice[:params] = Object.new }
        .to raise_error(Airbrake::Error, 'Got Object value, wanted a Hash')
    end
  end

  describe "#stash" do
    subject { described_class.new(AirbrakeTestError.new) }

    it { is_expected.to respond_to(:stash) }
  end
end
