require 'simplecov'
SimpleCov.start if ENV['COVERAGE']

require 'airbrake-ruby'

require 'rspec/its'

require 'webmock'
require 'webmock/rspec'
require 'pry'

require 'pathname'
require 'webrick'
require 'English'
require 'base64'
require 'pp'

require 'helpers'

RSpec.configure do |c|
  c.order = 'random'
  c.color = true
  c.disable_monkey_patching!
  c.include Helpers
end

Thread.abort_on_exception = true

WebMock.disable_net_connect!(allow_localhost: true)

class AirbrakeTestError < RuntimeError
  attr_reader :backtrace

  def initialize(*)
    super
    # rubocop:disable Layout/LineLength
    @backtrace = [
      "/home/kyrylo/code/airbrake/ruby/spec/spec_helper.rb:23:in `<top (required)>'",
      "/opt/rubies/ruby-2.2.2/lib/ruby/2.2.0/rubygems/core_ext/kernel_require.rb:54:in `require'",
      "/opt/rubies/ruby-2.2.2/lib/ruby/2.2.0/rubygems/core_ext/kernel_require.rb:54:in `require'",
      "/home/kyrylo/code/airbrake/ruby/spec/airbrake_spec.rb:1:in `<top (required)>'",
      "/home/kyrylo/.gem/ruby/2.2.2/gems/rspec-core-3.3.2/lib/rspec/core/configuration.rb:1327:in `load'",
      "/home/kyrylo/.gem/ruby/2.2.2/gems/rspec-core-3.3.2/lib/rspec/core/configuration.rb:1327:in `block in load_spec_files'",
      "/home/kyrylo/.gem/ruby/2.2.2/gems/rspec-core-3.3.2/lib/rspec/core/configuration.rb:1325:in `each'",
      "/home/kyrylo/.gem/ruby/2.2.2/gems/rspec-core-3.3.2/lib/rspec/core/configuration.rb:1325:in `load_spec_files'",
      "/home/kyrylo/.gem/ruby/2.2.2/gems/rspec-core-3.3.2/lib/rspec/core/runner.rb:102:in `setup'",
      "/home/kyrylo/.gem/ruby/2.2.2/gems/rspec-core-3.3.2/lib/rspec/core/runner.rb:88:in `run'",
      "/home/kyrylo/.gem/ruby/2.2.2/gems/rspec-core-3.3.2/lib/rspec/core/runner.rb:73:in `run'",
      "/home/kyrylo/.gem/ruby/2.2.2/gems/rspec-core-3.3.2/lib/rspec/core/runner.rb:41:in `invoke'",
      "/home/kyrylo/.gem/ruby/2.2.2/gems/rspec-core-3.3.2/exe/rspec:4:in `<main>'",
    ]
    # rubocop:enable Layout/LineLength
  end

  # rubocop:disable Naming/AccessorMethodName
  def set_backtrace(backtrace)
    @backtrace = backtrace
  end
  # rubocop:enable Naming/AccessorMethodName

  def message
    'App crashed!'
  end
end

class JavaAirbrakeTestError < AirbrakeTestError
  def initialize(*)
    super
    # rubocop:disable Layout/LineLength
    @backtrace = [
      "org.jruby.java.invokers.InstanceMethodInvoker.call(InstanceMethodInvoker.java:26)",
      "org.jruby.ir.interpreter.Interpreter.INTERPRET_EVAL(Interpreter.java:126)",
      "org.jruby.RubyKernel$INVOKER$s$0$3$eval19.call(RubyKernel$INVOKER$s$0$3$eval19.gen)",
      "org.jruby.RubyKernel$INVOKER$s$0$0$loop.call(RubyKernel$INVOKER$s$0$0$loop.gen)",
      "org.jruby.runtime.IRBlockBody.doYield(IRBlockBody.java:139)",
      "org.jruby.RubyKernel$INVOKER$s$rbCatch19.call(RubyKernel$INVOKER$s$rbCatch19.gen)",
      "opt.rubies.jruby_minus_9_dot_0_dot_0_dot_0.bin.irb.invokeOther4:start(/opt/rubies/jruby-9.0.0.0/bin/irb)",
      "opt.rubies.jruby_minus_9_dot_0_dot_0_dot_0.bin.irb.RUBY$script(/opt/rubies/jruby-9.0.0.0/bin/irb:13)",
      "org.jruby.ir.Compiler$1.load(Compiler.java:111)",
      "org.jruby.Main.run(Main.java:225)",
      "org.jruby.Main.main(Main.java:197)",
    ]
    # rubocop:enable Layout/LineLength
  end

  def is_a?(*)
    true
  end
end

class Ruby21Error < RuntimeError
  attr_accessor :cause

  def self.raise_error(msg)
    ex = new(msg)
    ex.cause = $ERROR_INFO

    raise ex
  end
end
