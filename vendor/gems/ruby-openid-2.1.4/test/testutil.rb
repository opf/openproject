require "pathname"

module OpenID
  module TestDataMixin
    TESTS_DIR = Pathname.new(__FILE__).dirname
    TEST_DATA_DIR = Pathname.new('data')

    def read_data_file(filename, lines=true, data_dir=TEST_DATA_DIR)
      fname = TESTS_DIR.join(data_dir, filename)

      if lines
        fname.readlines
      else
        fname.read
      end
    end
  end

  module FetcherMixin
    def with_fetcher(fetcher)
      original_fetcher = OpenID.fetcher
      begin
        OpenID.fetcher = fetcher
        return yield
      ensure
        OpenID.fetcher = original_fetcher
      end
    end
  end

  module Const
    def const(symbol, value)
      (class << self;self;end).instance_eval do
        define_method(symbol) { value }
      end
    end
  end

  class MockResponse
    attr_reader :code, :body

    def initialize(code, body)
      @code = code.to_s
      @body = body
    end
  end

  module ProtocolErrorMixin
    def assert_protocol_error(str_prefix)
      begin
        result = yield
      rescue ProtocolError => why
        message = "Expected prefix #{str_prefix.inspect}, got "\
                  "#{why.message.inspect}"
        assert(why.message.starts_with?(str_prefix), message)
      else
        fail("Expected ProtocolError. Got #{result.inspect}")
      end
    end
  end

  module OverrideMethodMixin
    def with_method_overridden(method_name, proc)
      original = method(method_name)
      begin
        # TODO: find a combination of undef calls which prevent the warning
        verbose, $VERBOSE = $VERBOSE, false
        define_method(method_name, proc)
        module_function(method_name)
        $VERBOSE = verbose
        yield
      ensure
        if original.respond_to? :owner
          original.owner.send(:undef_method, method_name)
          original.owner.send :define_method, method_name, original
        else
          define_method(method_name, original)
          module_function(method_name)
        end
      end
    end
  end

  # To use:
  # > x = Object.new
  # > x.extend(InstanceDefExtension)
  # > x.instance_def(:monkeys) do
  # >   "bananas"
  # > end
  # > x.monkeys
  #
  module InstanceDefExtension
    def instance_def(method_name, &proc)
      (class << self;self;end).instance_eval do
        # TODO: find a combination of undef calls which prevent the warning
        verbose, $VERBOSE = $VERBOSE, false
        define_method(method_name, proc)
        $VERBOSE = verbose
      end
    end
  end

  GOODSIG = '[A Good Signature]'

  class GoodAssoc
    attr_accessor :handle, :expires_in

    def initialize(handle='-blah-')
      @handle = handle
      @expires_in = 3600
    end

    def check_message_signature(msg)
      msg.get_arg(OPENID_NS, 'sig') == GOODSIG
    end
  end

  class HTTPResponse
    def self._from_raw_data(status, body="", headers={}, final_url=nil)
      resp = Net::HTTPResponse.new('1.1', status.to_s, 'NONE')
      me = self._from_net_response(resp, final_url)
      me.initialize_http_header headers
      me.body = body
      return me
    end
  end
end
