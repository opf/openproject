RSpec.describe Airbrake::Backtrace do
  describe ".parse" do
    context "UNIX backtrace" do
      let(:parsed_backtrace) do
        # rubocop:disable Layout/LineLength, Style/HashSyntax, Layout/SpaceAroundOperators, Layout/SpaceInsideHashLiteralBraces
        [{:file=>"/home/kyrylo/code/airbrake/ruby/spec/spec_helper.rb", :line=>23, :function=>"<top (required)>"},
         {:file=>"/opt/rubies/ruby-2.2.2/lib/ruby/2.2.0/rubygems/core_ext/kernel_require.rb", :line=>54, :function=>"require"},
         {:file=>"/opt/rubies/ruby-2.2.2/lib/ruby/2.2.0/rubygems/core_ext/kernel_require.rb", :line=>54, :function=>"require"},
         {:file=>"/home/kyrylo/code/airbrake/ruby/spec/airbrake_spec.rb", :line=>1, :function=>"<top (required)>"},
         {:file=>"/home/kyrylo/.gem/ruby/2.2.2/gems/rspec-core-3.3.2/lib/rspec/core/configuration.rb", :line=>1327, :function=>"load"},
         {:file=>"/home/kyrylo/.gem/ruby/2.2.2/gems/rspec-core-3.3.2/lib/rspec/core/configuration.rb", :line=>1327, :function=>"block in load_spec_files"},
         {:file=>"/home/kyrylo/.gem/ruby/2.2.2/gems/rspec-core-3.3.2/lib/rspec/core/configuration.rb", :line=>1325, :function=>"each"},
         {:file=>"/home/kyrylo/.gem/ruby/2.2.2/gems/rspec-core-3.3.2/lib/rspec/core/configuration.rb", :line=>1325, :function=>"load_spec_files"},
         {:file=>"/home/kyrylo/.gem/ruby/2.2.2/gems/rspec-core-3.3.2/lib/rspec/core/runner.rb", :line=>102, :function=>"setup"},
         {:file=>"/home/kyrylo/.gem/ruby/2.2.2/gems/rspec-core-3.3.2/lib/rspec/core/runner.rb", :line=>88, :function=>"run"},
         {:file=>"/home/kyrylo/.gem/ruby/2.2.2/gems/rspec-core-3.3.2/lib/rspec/core/runner.rb", :line=>73, :function=>"run"},
         {:file=>"/home/kyrylo/.gem/ruby/2.2.2/gems/rspec-core-3.3.2/lib/rspec/core/runner.rb", :line=>41, :function=>"invoke"},
         {:file=>"/home/kyrylo/.gem/ruby/2.2.2/gems/rspec-core-3.3.2/exe/rspec", :line=>4, :function=>"<main>"}]
        # rubocop:enable Layout/LineLength, Style/HashSyntax, Layout/SpaceAroundOperators, Layout/SpaceInsideHashLiteralBraces
      end

      it "returns a properly formatted array of hashes" do
        expect(described_class.parse(AirbrakeTestError.new))
          .to eq(parsed_backtrace)
      end
    end

    context "Windows backtrace" do
      let(:windows_bt) do
        ["C:/Program Files/Server/app/models/user.rb:13:in `magic'",
         "C:/Program Files/Server/app/controllers/users_controller.rb:8:in `index'"]
      end

      let(:ex) { AirbrakeTestError.new.tap { |e| e.set_backtrace(windows_bt) } }

      let(:parsed_backtrace) do
        # rubocop:disable Layout/LineLength, Style/HashSyntax, Layout/SpaceInsideHashLiteralBraces, Layout/SpaceAroundOperators
        [{:file=>"C:/Program Files/Server/app/models/user.rb", :line=>13, :function=>"magic"},
         {:file=>"C:/Program Files/Server/app/controllers/users_controller.rb", :line=>8, :function=>"index"}]
        # rubocop:enable Layout/LineLength, Style/HashSyntax, Layout/SpaceInsideHashLiteralBraces, Layout/SpaceAroundOperators
      end

      it "returns a properly formatted array of hashes" do
        expect(described_class.parse(ex)).to eq(parsed_backtrace)
      end
    end

    context "JRuby Java exceptions" do
      let(:backtrace_array) do
        # rubocop:disable Layout/LineLength, Style/HashSyntax, Layout/SpaceInsideHashLiteralBraces, Layout/SpaceAroundOperators
        [{:file=>"InstanceMethodInvoker.java", :line=>26, :function=>"org.jruby.java.invokers.InstanceMethodInvoker.call"},
         {:file=>"Interpreter.java", :line=>126, :function=>"org.jruby.ir.interpreter.Interpreter.INTERPRET_EVAL"},
         {:file=>"RubyKernel$INVOKER$s$0$3$eval19.gen", :line=>nil, :function=>"org.jruby.RubyKernel$INVOKER$s$0$3$eval19.call"},
         {:file=>"RubyKernel$INVOKER$s$0$0$loop.gen", :line=>nil, :function=>"org.jruby.RubyKernel$INVOKER$s$0$0$loop.call"},
         {:file=>"IRBlockBody.java", :line=>139, :function=>"org.jruby.runtime.IRBlockBody.doYield"},
         {:file=>"RubyKernel$INVOKER$s$rbCatch19.gen", :line=>nil, :function=>"org.jruby.RubyKernel$INVOKER$s$rbCatch19.call"},
         {:file=>"/opt/rubies/jruby-9.0.0.0/bin/irb", :line=>nil, :function=>"opt.rubies.jruby_minus_9_dot_0_dot_0_dot_0.bin.irb.invokeOther4:start"},
         {:file=>"/opt/rubies/jruby-9.0.0.0/bin/irb", :line=>13, :function=>"opt.rubies.jruby_minus_9_dot_0_dot_0_dot_0.bin.irb.RUBY$script"},
         {:file=>"Compiler.java", :line=>111, :function=>"org.jruby.ir.Compiler$1.load"},
         {:file=>"Main.java", :line=>225, :function=>"org.jruby.Main.run"},
         {:file=>"Main.java", :line=>197, :function=>"org.jruby.Main.main"}]
        # rubocop:enable Layout/LineLength, Style/HashSyntax, Layout/SpaceInsideHashLiteralBraces, Layout/SpaceAroundOperators
      end

      it "returns a properly formatted array of hashes" do
        allow(described_class).to receive(:java_exception?).and_return(true)

        expect(described_class.parse(JavaAirbrakeTestError.new))
          .to eq(backtrace_array)
      end
    end

    context "JRuby classloader exceptions" do
      let(:backtrace) do
        # rubocop:disable Layout/LineLength
        ['uri_3a_classloader_3a_.META_minus_INF.jruby_dot_home.lib.ruby.stdlib.net.protocol.rbuf_fill(uri:classloader:/META-INF/jruby.home/lib/ruby/stdlib/net/protocol.rb:158)',
         'bin.processors.image_uploader.block in make_streams(bin/processors/image_uploader.rb:21)',
         'uri_3a_classloader_3a_.gems.faye_minus_websocket_minus_0_dot_10_dot_5.lib.faye.websocket.api.invokeOther13:dispatch_event(uri_3a_classloader_3a_/gems/faye_minus_websocket_minus_0_dot_10_dot_5/lib/faye/websocket/uri:classloader:/gems/faye-websocket-0.10.5/lib/faye/websocket/api.rb:109)',
         'tmp.jruby9022301782566983632extract.$dot.META_minus_INF.rails.file(/tmp/jruby9022301782566983632extract/./META-INF/rails.rb:13)']
        # rubocop:enable Layout/LineLength
      end

      let(:parsed_backtrace) do
        # rubocop:disable Layout/LineLength
        [{ file: 'uri:classloader:/META-INF/jruby.home/lib/ruby/stdlib/net/protocol.rb', line: 158, function: 'uri_3a_classloader_3a_.META_minus_INF.jruby_dot_home.lib.ruby.stdlib.net.protocol.rbuf_fill' },
         { file: 'bin/processors/image_uploader.rb', line: 21, function: 'bin.processors.image_uploader.block in make_streams' },
         { file: 'uri_3a_classloader_3a_/gems/faye_minus_websocket_minus_0_dot_10_dot_5/lib/faye/websocket/uri:classloader:/gems/faye-websocket-0.10.5/lib/faye/websocket/api.rb', line: 109, function: 'uri_3a_classloader_3a_.gems.faye_minus_websocket_minus_0_dot_10_dot_5.lib.faye.websocket.api.invokeOther13:dispatch_event' },
         { file: '/tmp/jruby9022301782566983632extract/./META-INF/rails.rb', line: 13, function: 'tmp.jruby9022301782566983632extract.$dot.META_minus_INF.rails.file' }]
        # rubocop:enable Layout/LineLength
      end

      let(:ex) { JavaAirbrakeTestError.new.tap { |e| e.set_backtrace(backtrace) } }

      it "returns a properly formatted array of hashes" do
        allow(described_class).to receive(:java_exception?).and_return(true)
        expect(described_class.parse(ex)).to eq(parsed_backtrace)
      end
    end

    context "JRuby non-throwable exceptions" do
      let(:backtrace) do
        # rubocop:disable Layout/LineLength
        ['org.postgresql.core.v3.ConnectionFactoryImpl.openConnectionImpl(org/postgresql/core/v3/ConnectionFactoryImpl.java:257)',
         'org.postgresql.core.ConnectionFactory.openConnection(org/postgresql/core/ConnectionFactory.java:65)',
         'org.postgresql.jdbc2.AbstractJdbc2Connection.<init>(org/postgresql/jdbc2/AbstractJdbc2Connection.java:149)']
        # rubocop:enable Layout/LineLength
      end

      let(:parsed_backtrace) do
        # rubocop:disable Layout/LineLength
        [{ file: 'org/postgresql/core/v3/ConnectionFactoryImpl.java', line: 257, function: 'org.postgresql.core.v3.ConnectionFactoryImpl.openConnectionImpl' },
         { file: 'org/postgresql/core/ConnectionFactory.java', line: 65, function: 'org.postgresql.core.ConnectionFactory.openConnection' },
         { file: 'org/postgresql/jdbc2/AbstractJdbc2Connection.java', line: 149, function: 'org.postgresql.jdbc2.AbstractJdbc2Connection.<init>' }]
        # rubocop:enable Layout/LineLength
      end

      let(:ex) { AirbrakeTestError.new.tap { |e| e.set_backtrace(backtrace) } }

      it "returns a properly formatted array of hashes" do
        expect(described_class.parse(ex)).to eq(parsed_backtrace)
      end
    end

    context "generic backtrace" do
      context "when function is absent" do
        # rubocop:disable Layout/LineLength
        let(:generic_bt) do
          ["/home/bingo/bango/assets/stylesheets/error_pages.scss:139:in `animation'",
           "/home/bingo/bango/assets/stylesheets/error_pages.scss:139",
           "/home/bingo/.gem/ruby/2.2.2/gems/sass-3.4.20/lib/sass/tree/visitors/perform.rb:349:in `block in visit_mixin'"]
        end
        # rubocop:enable Layout/LineLength

        let(:ex) { AirbrakeTestError.new.tap { |e| e.set_backtrace(generic_bt) } }

        let(:parsed_backtrace) do
          # rubocop:disable Layout/LineLength, Style/HashSyntax, Layout/SpaceInsideHashLiteralBraces, Layout/SpaceAroundOperators
          [{:file=>"/home/bingo/bango/assets/stylesheets/error_pages.scss", :line=>139, :function=>"animation"},
           {:file=>"/home/bingo/bango/assets/stylesheets/error_pages.scss", :line=>139, :function=>nil},
           {:file=>"/home/bingo/.gem/ruby/2.2.2/gems/sass-3.4.20/lib/sass/tree/visitors/perform.rb", :line=>349, :function=>"block in visit_mixin"}]
          # rubocop:enable Layout/LineLength, Style/HashSyntax, Layout/SpaceInsideHashLiteralBraces, Layout/SpaceAroundOperators
        end

        it "returns a properly formatted array of hashes" do
          expect(described_class.parse(ex)).to eq(parsed_backtrace)
        end
      end

      context "when line is absent" do
        let(:generic_bt) do
          ["/Users/grammakov/repositories/weintervene/config.ru:in `new'"]
        end

        let(:ex) { AirbrakeTestError.new.tap { |e| e.set_backtrace(generic_bt) } }

        let(:parsed_backtrace) do
          [{ file: '/Users/grammakov/repositories/weintervene/config.ru',
             line: nil,
             function: 'new' }]
        end

        it "returns a properly formatted array of hashes" do
          expect(described_class.parse(ex)).to eq(parsed_backtrace)
        end
      end
    end

    context "unknown backtrace" do
      let(:unknown_bt) { ['a b c 1 23 321 .rb'] }

      let(:ex) { AirbrakeTestError.new.tap { |e| e.set_backtrace(unknown_bt) } }

      it "returns array of hashes where each unknown frame is marked as 'function'" do
        expect(
          described_class.parse(ex),
        ).to eq([file: nil, line: nil, function: 'a b c 1 23 321 .rb'])
      end

      it "logs frames that cannot be parsed" do
        expect(Airbrake::Loggable.instance).to receive(:error).with(
          /can't parse 'a b c 1 23 321 .rb'/,
        )
        described_class.parse(ex)
      end
    end

    context "given a backtrace with an empty function" do
      let(:bt) do
        ["/airbrake-ruby/vendor/jruby/1.9/gems/rspec-core-3.4.1/exe/rspec:3:in `'"]
      end

      let(:ex) { AirbrakeTestError.new.tap { |e| e.set_backtrace(bt) } }

      let(:parsed_backtrace) do
        [{ file: '/airbrake-ruby/vendor/jruby/1.9/gems/rspec-core-3.4.1/exe/rspec',
           line: 3,
           function: '' }]
      end

      it "returns a properly formatted array of hashes" do
        expect(described_class.parse(ex)).to eq(parsed_backtrace)
      end
    end

    context "given an Oracle backtrace" do
      let(:bt) do
        ['ORA-06512: at "STORE.LI_LICENSES_PACK", line 1945',
         'ORA-06512: at "ACTIVATION.LI_ACT_LICENSES_PACK", line 101',
         'ORA-06512: at line 2',
         'from stmt.c:243:in oci8lib_220.bundle']
      end

      let(:ex) { OCIError.new.tap { |e| e.set_backtrace(bt) } }

      let(:parsed_backtrace) do
        [{ file: nil, line: 1945, function: 'STORE.LI_LICENSES_PACK' },
         { file: nil, line: 101, function: 'ACTIVATION.LI_ACT_LICENSES_PACK' },
         { file: nil, line: 2, function: nil },
         { file: 'stmt.c', line: 243, function: 'oci8lib_220.bundle' }]
      end

      it "returns a properly formatted array of hashes" do
        stub_const('OCIError', AirbrakeTestError)
        expect(described_class.parse(ex)).to eq(parsed_backtrace)
      end
    end

    context "given an ExecJS exception" do
      let(:bt) do
        ['compile ((execjs):6692:19)',
         'eval (<anonymous>:1:10)',
         '(execjs):6703:8',
         'require../helpers.exports ((execjs):1:102)',
         'Object.<anonymous> ((execjs):1:120)',
         'Object.Module._extensions..js (module.js:550:10)',
         'bootstrap_node.js:467:3',
         "/opt/rubies/ruby-2.3.1/lib/ruby/2.3.0/benchmark.rb:308:in `realtime'"]
      end

      let(:ex) { ExecJS::RuntimeError.new.tap { |e| e.set_backtrace(bt) } }

      let(:parsed_backtrace) do
        [{ file: '(execjs)', line: 6692, function: 'compile' },
         { file: '<anonymous>', line: 1, function: 'eval' },
         { file: '(execjs)', line: 6703, function: '' },
         { file: '(execjs)', line: 1, function: 'require../helpers.exports' },
         { file: '(execjs)', line: 1, function: 'Object.<anonymous>' },
         { file: 'module.js', line: 550, function: 'Object.Module._extensions..js' },
         { file: 'bootstrap_node.js', line: 467, function: '' },
         { file: '/opt/rubies/ruby-2.3.1/lib/ruby/2.3.0/benchmark.rb',
           line: 308,
           function: 'realtime' }]
      end

      it "returns a properly formatted array of hashes" do
        stub_const('ExecJS::RuntimeError', AirbrakeTestError)
        expect(described_class.parse(ex)).to eq(parsed_backtrace)
      end
    end

    context "when code hunks are enabled" do
      before { Airbrake::Config.instance.merge(code_hunks: true) }

      context "and when root_directory is configured" do
        before do
          Airbrake::Config.instance.merge(root_directory: project_root_path(''))
        end

        let(:parsed_backtrace) do
          [
            {
              file: project_root_path('code.rb'),
              line: 94,
              function: 'to_json',
              code: {
                92 => '      loop do',
                93 => '        begin',
                94 => '          json = @payload.to_json',
                95 => '        rescue *JSON_EXCEPTIONS => ex',
                # rubocop:disable Layout/LineLength,Lint/InterpolationCheck
                96 => '          @config.logger.debug("#{LOG_LABEL} `notice.to_json` failed: #{ex.class}: #{ex}")',
                # rubocop:enable Layout/LineLength,Lint/InterpolationCheck
              },
            },
            {
              file: fixture_path('notroot.txt'),
              line: 3,
              function: 'pineapple',
            },
            {
              file: project_root_path('vendor/bundle/ignored_file.rb'),
              line: 2,
              function: 'ignore_me',
            },
          ]
        end

        it "attaches code to those frames files of which match root_directory" do
          ex = RuntimeError.new
          backtrace = [
            project_root_path('code.rb') + ":94:in `to_json'",
            fixture_path('notroot.txt' + ":3:in `pineapple'"),
            project_root_path('vendor/bundle/ignored_file.rb') + ":2:in `ignore_me'",
          ]
          ex.set_backtrace(backtrace)
          expect(described_class.parse(ex)).to eq(parsed_backtrace)
        end
      end

      context "and when root_directory is a Pathname" do
        before do
          Airbrake::Config.instance.merge(
            root_directory: Pathname.new(project_root_path('')),
          )
        end

        let(:parsed_backtrace) do
          [
            {
              file: project_root_path('code.rb'),
              line: 94,
              function: 'to_json',
              code: {
                92 => '      loop do',
                93 => '        begin',
                94 => '          json = @payload.to_json',
                95 => '        rescue *JSON_EXCEPTIONS => ex',
                # rubocop:disable Layout/LineLength,Lint/InterpolationCheck
                96 => '          @config.logger.debug("#{LOG_LABEL} `notice.to_json` failed: #{ex.class}: #{ex}")',
                # rubocop:enable Layout/LineLength,Lint/InterpolationCheck
              },
            },
          ]
        end

        it "attaches code to those frames files of which match root_directory" do
          ex = RuntimeError.new
          ex.set_backtrace([project_root_path('code.rb') + ":94:in `to_json'"])
          expect(described_class.parse(ex)).to eq(parsed_backtrace)
        end
      end

      context "and when root_directory isn't configured" do
        before do
          Airbrake::Config.instance.merge(root_directory: nil)
          stub_const('Airbrake::Backtrace::CODE_FRAME_LIMIT', 2)
        end

        let(:parsed_backtrace) do
          [
            {
              file: project_root_path('code.rb'),
              line: 94,
              function: 'to_json',
              code: {
                92 => '      loop do',
                93 => '        begin',
                94 => '          json = @payload.to_json',
                95 => '        rescue *JSON_EXCEPTIONS => ex',
                # rubocop:disable Layout/LineLength,Lint/InterpolationCheck
                96 => '          @config.logger.debug("#{LOG_LABEL} `notice.to_json` failed: #{ex.class}: #{ex}")',
                # rubocop:enable Layout/LineLength,Lint/InterpolationCheck
              },
            },
            {
              file: project_root_path('code.rb'),
              line: 95,
              function: 'to_json',
              code: {
                93 => '        begin',
                94 => '          json = @payload.to_json',
                95 => '        rescue *JSON_EXCEPTIONS => ex',
                # rubocop:disable Layout/LineLength,Lint/InterpolationCheck
                96 => '          @config.logger.debug("#{LOG_LABEL} `notice.to_json` failed: #{ex.class}: #{ex}")',
                # rubocop:enable Layout/LineLength,Lint/InterpolationCheck
                97 => '        else',
              },
            },
            {
              file: project_root_path('code.rb'),
              line: 96,
              function: 'to_json',
            },
          ]
        end

        it "attaches code to first N frames" do
          ex = RuntimeError.new
          backtrace = [
            project_root_path('code.rb') + ":94:in `to_json'",
            project_root_path('code.rb') + ":95:in `to_json'",
            project_root_path('code.rb') + ":96:in `to_json'",
          ]
          ex.set_backtrace(backtrace)
          expect(described_class.parse(ex)).to eq(parsed_backtrace)
        end
      end
    end

    context "when code hunks are disabled" do
      before { Airbrake::Config.instance.merge(code_hunks: false) }

      context "and when root_directory is configured" do
        before do
          Airbrake::Config.instance.merge(root_directory: project_root_path(''))
        end

        let(:parsed_backtrace) do
          [
            {
              file: project_root_path('code.rb'),
              line: 94,
              function: 'to_json',
            },
          ]
        end

        it "doesn't attach code to frames" do
          ex = RuntimeError.new
          backtrace = [project_root_path('code.rb') + ":94:in `to_json'"]
          ex.set_backtrace(backtrace)
          expect(described_class.parse(ex)).to eq(parsed_backtrace)
        end
      end
    end
  end
end
