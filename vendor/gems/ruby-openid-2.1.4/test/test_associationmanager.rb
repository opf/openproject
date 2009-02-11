require "openid/consumer/associationmanager"
require "openid/association"
require "openid/dh"
require "openid/util"
require "openid/cryptutil"
require "openid/message"
require "openid/store/memory"
require "test/unit"
require "util"
require "time"

module OpenID
  class DHAssocSessionTest < Test::Unit::TestCase
    def test_sha1_get_request
      # Initialized without an explicit DH gets defaults
      sess = Consumer::DiffieHellmanSHA1Session.new
      assert_equal(['dh_consumer_public'], sess.get_request.keys)
      assert_nothing_raised do
        Util::from_base64(sess.get_request['dh_consumer_public'])
      end
    end

    def test_sha1_get_request_custom_dh
      dh = DiffieHellman.new(1299721, 2)
      sess = Consumer::DiffieHellmanSHA1Session.new(dh)
      req = sess.get_request
      assert_equal(['dh_consumer_public', 'dh_modulus', 'dh_gen'].sort,
                   req.keys.sort)
      assert_equal(dh.modulus, CryptUtil.base64_to_num(req['dh_modulus']))
      assert_equal(dh.generator, CryptUtil.base64_to_num(req['dh_gen']))
      assert_nothing_raised do
        Util::from_base64(req['dh_consumer_public'])
      end
    end
  end

  module TestDiffieHellmanResponseParametersMixin
    def setup
      session_cls = self.class.session_cls

      # Pre-compute DH with small prime so tests run quickly.
      @server_dh = DiffieHellman.new(100389557, 2)
      @consumer_dh = DiffieHellman.new(100389557, 2)

      # base64(btwoc(g ^ xb mod p))
      @dh_server_public = CryptUtil.num_to_base64(@server_dh.public)

      @secret = CryptUtil.random_string(session_cls.secret_size)

      enc_mac_key_unencoded =
        @server_dh.xor_secret(session_cls.hashfunc,
                              @consumer_dh.public,
                              @secret)

      @enc_mac_key = Util.to_base64(enc_mac_key_unencoded)

      @consumer_session = session_cls.new(@consumer_dh)

      @msg = Message.new(self.class.message_namespace)
    end

    def test_extract_secret
      @msg.set_arg(OPENID_NS, 'dh_server_public', @dh_server_public)
      @msg.set_arg(OPENID_NS, 'enc_mac_key', @enc_mac_key)

      extracted = @consumer_session.extract_secret(@msg)
      assert_equal(extracted, @secret)
    end

    def test_absent_serve_public
      @msg.set_arg(OPENID_NS, 'enc_mac_key', @enc_mac_key)

      assert_raises(Message::KeyNotFound) {
        @consumer_session.extract_secret(@msg)
      }
    end

    def test_absent_mac_key
      @msg.set_arg(OPENID_NS, 'dh_server_public', @dh_server_public)

      assert_raises(Message::KeyNotFound) {
        @consumer_session.extract_secret(@msg)
      }
    end

    def test_invalid_base64_public
      @msg.set_arg(OPENID_NS, 'dh_server_public', 'n o t b a s e 6 4.')
      @msg.set_arg(OPENID_NS, 'enc_mac_key', @enc_mac_key)

      assert_raises(ArgumentError) {
        @consumer_session.extract_secret(@msg)
      }
    end

    def test_invalid_base64_mac_key
      @msg.set_arg(OPENID_NS, 'dh_server_public', @dh_server_public)
      @msg.set_arg(OPENID_NS, 'enc_mac_key', 'n o t base 64')

      assert_raises(ArgumentError) {
        @consumer_session.extract_secret(@msg)
      }
    end
  end

  class TestConsumerOpenID1DHSHA1 < Test::Unit::TestCase
    include TestDiffieHellmanResponseParametersMixin
    class << self
      attr_reader :session_cls, :message_namespace
    end

    @session_cls = Consumer::DiffieHellmanSHA1Session
    @message_namespace = OPENID1_NS
  end

  class TestConsumerOpenID2DHSHA1 < Test::Unit::TestCase
    include TestDiffieHellmanResponseParametersMixin
    class << self
      attr_reader :session_cls, :message_namespace
    end

    @session_cls = Consumer::DiffieHellmanSHA1Session
    @message_namespace = OPENID2_NS
  end

  class TestConsumerOpenID2DHSHA256 < Test::Unit::TestCase
    include TestDiffieHellmanResponseParametersMixin
    class << self
      attr_reader :session_cls, :message_namespace
    end

    @session_cls = Consumer::DiffieHellmanSHA256Session
    @message_namespace = OPENID2_NS
  end

  class TestConsumerNoEncryptionSession < Test::Unit::TestCase
    def setup
      @sess = Consumer::NoEncryptionSession.new
    end

    def test_empty_request
      assert_equal(@sess.get_request, {})
    end

    def test_get_secret
      secret = 'shhh!' * 4
      mac_key = Util.to_base64(secret)
      msg = Message.from_openid_args({'mac_key' => mac_key})
      assert_equal(secret, @sess.extract_secret(msg))
    end
  end

  class TestCreateAssociationRequest < Test::Unit::TestCase
    def setup
      @server_url = 'http://invalid/'
      @assoc_manager = Consumer::AssociationManager.new(nil, @server_url)
      class << @assoc_manager
        def compatibility_mode=(val)
            @compatibility_mode = val
        end
      end
      @assoc_type = 'HMAC-SHA1'
    end

    def test_no_encryption_sends_type
      session_type = 'no-encryption'
      session, args = @assoc_manager.send(:create_associate_request,
                                          @assoc_type,
                                          session_type)

      assert(session.is_a?(Consumer::NoEncryptionSession))
      expected = Message.from_openid_args(
            {'ns' => OPENID2_NS,
             'session_type' => session_type,
             'mode' => 'associate',
             'assoc_type' => @assoc_type,
             })

      assert_equal(expected, args)
    end

    def test_no_encryption_compatibility
      @assoc_manager.compatibility_mode = true
      session_type = 'no-encryption'
      session, args = @assoc_manager.send(:create_associate_request,
                                          @assoc_type,
                                          session_type)

      assert(session.is_a?(Consumer::NoEncryptionSession))
      assert_equal(Message.from_openid_args({'mode' => 'associate',
                                              'assoc_type' => @assoc_type,
                                            }), args)
    end

    def test_dh_sha1_compatibility
      @assoc_manager.compatibility_mode = true
      session_type = 'DH-SHA1'
      session, args = @assoc_manager.send(:create_associate_request,
                                          @assoc_type,
                                          session_type)


      assert(session.is_a?(Consumer::DiffieHellmanSHA1Session))

      # This is a random base-64 value, so just check that it's
      # present.
      assert_not_nil(args.get_arg(OPENID1_NS, 'dh_consumer_public'))
      args.del_arg(OPENID1_NS, 'dh_consumer_public')

      # OK, session_type is set here and not for no-encryption
      # compatibility
      expected = Message.from_openid_args({'mode' => 'associate',
                                            'session_type' => 'DH-SHA1',
                                            'assoc_type' => @assoc_type,
                                          })
      assert_equal(expected, args)
    end
  end

  class TestAssociationManagerExpiresIn < Test::Unit::TestCase
    def expires_in_msg(val)
      msg = Message.from_openid_args({'expires_in' => val})
      Consumer::AssociationManager.extract_expires_in(msg)
    end

    def test_parse_fail
      ['',
       '-2',
       ' 1',
       ' ',
       '0x00',
       'foosball',
       '1\n',
       '100,000,000,000',
      ].each do |x|
        assert_raises(ProtocolError) {expires_in_msg(x)}
      end
    end

    def test_parse
      ['0',
       '1',
       '1000',
       '9999999',
       '01',
      ].each do |n|
        assert_equal(n.to_i, expires_in_msg(n))
      end
    end
  end

  class TestAssociationManagerCreateSession < Test::Unit::TestCase
    def test_invalid
      assert_raises(ArgumentError) {
        Consumer::AssociationManager.create_session('monkeys')
      }
    end

    def test_sha256
      sess = Consumer::AssociationManager.create_session('DH-SHA256')
      assert(sess.is_a?(Consumer::DiffieHellmanSHA256Session))
    end
  end

  module NegotiationTestMixin
    include TestUtil
    def mk_message(args)
      args['ns'] = @openid_ns
      Message.from_openid_args(args)
    end

    def call_negotiate(responses, negotiator=nil)
      store = nil
      compat = self.class::Compat
      assoc_manager = Consumer::AssociationManager.new(store, @server_url,
                                                       compat, negotiator)
      class << assoc_manager
        attr_accessor :responses

        def request_association(assoc_type, session_type)
          m = @responses.shift
          if m.is_a?(Message)
            raise ServerError.from_message(m)
          else
            return m
          end
        end
      end
      assoc_manager.responses = responses
      assoc_manager.negotiate_association
    end
  end

  # Test the session type negotiation behavior of an OpenID 2
  # consumer.
  class TestOpenID2SessionNegotiation < Test::Unit::TestCase
    include NegotiationTestMixin

    Compat = false

    def setup
      @server_url = 'http://invalid/'
      @openid_ns = OPENID2_NS
    end

    # Test the case where the response to an associate request is a
    # server error or is otherwise undecipherable.
    def test_bad_response
      assert_log_matches('Server error when requesting an association') {
        assert_equal(call_negotiate([mk_message({})]), nil)
      }
    end

    # Test the case where the association type (assoc_type) returned
    # in an unsupported-type response is absent.
    def test_empty_assoc_type
      msg = mk_message({'error' => 'Unsupported type',
                              'error_code' => 'unsupported-type',
                              'session_type' => 'new-session-type',
                            })

      assert_log_matches('Unsupported association type',
                         "Server #{@server_url} responded with unsupported "\
                         "association session but did not supply a fallback."
                         ) {
        assert_equal(call_negotiate([msg]), nil)
      }

    end

    # Test the case where the session type (session_type) returned
    # in an unsupported-type response is absent.
    def test_empty_session_type
      msg = mk_message({'error' => 'Unsupported type',
                              'error_code' => 'unsupported-type',
                              'assoc_type' => 'new-assoc-type',
                            })

      assert_log_matches('Unsupported association type',
                         "Server #{@server_url} responded with unsupported "\
                         "association session but did not supply a fallback."
                         ) {
        assert_equal(call_negotiate([msg]), nil)
      }
    end

    # Test the case where an unsupported-type response specifies a
    # preferred (assoc_type, session_type) combination that is not
    # allowed by the consumer's SessionNegotiator.
    def test_not_allowed
      negotiator = AssociationNegotiator.new([])
      negotiator.instance_eval{
        @allowed_types = [['assoc_bogus', 'session_bogus']]
      }
      msg = mk_message({'error' => 'Unsupported type',
                              'error_code' => 'unsupported-type',
                              'assoc_type' => 'not-allowed',
                              'session_type' => 'not-allowed',
                            })

      assert_log_matches('Unsupported association type',
                         'Server sent unsupported session/association type:') {
        assert_equal(call_negotiate([msg], negotiator), nil)
      }
    end

    # Test the case where an unsupported-type response triggers a
    # retry to get an association with the new preferred type.
    def test_unsupported_with_retry
      msg = mk_message({'error' => 'Unsupported type',
                              'error_code' => 'unsupported-type',
                              'assoc_type' => 'HMAC-SHA1',
                              'session_type' => 'DH-SHA1',
                            })

      assoc = Association.new('handle', 'secret', Time.now, 10000, 'HMAC-SHA1')

      assert_log_matches('Unsupported association type') {
        assert_equal(assoc, call_negotiate([msg, assoc]))
      }
    end

    # Test the case where an unsupported-typ response triggers a
    # retry, but the retry fails and nil is returned instead.
    def test_unsupported_with_retry_and_fail
      msg = mk_message({'error' => 'Unsupported type',
                              'error_code' => 'unsupported-type',
                              'assoc_type' => 'HMAC-SHA1',
                              'session_type' => 'DH-SHA1',
                            })

      assert_log_matches('Unsupported association type',
                         "Server #{@server_url} refused") {
        assert_equal(call_negotiate([msg, msg]), nil)
      }
    end

    # Test the valid case, wherein an association is returned on the
    # first attempt to get one.
    def test_valid
      assoc = Association.new('handle', 'secret', Time.now, 10000, 'HMAC-SHA1')

      assert_log_matches() {
        assert_equal(call_negotiate([assoc]), assoc)
      }
    end
  end


  # Tests for the OpenID 1 consumer association session behavior.  See
  # the docs for TestOpenID2SessionNegotiation.  Notice that this
  # class is not a subclass of the OpenID 2 tests.  Instead, it uses
  # many of the same inputs but inspects the log messages logged with
  # oidutil.log.  See the calls to self.failUnlessLogMatches.  Some of
  # these tests pass openid2-style messages to the openid 1
  # association processing logic to be sure it ignores the extra data.
  class TestOpenID1SessionNegotiation < Test::Unit::TestCase
    include NegotiationTestMixin

    Compat = true

    def setup
      @server_url = 'http://invalid/'
      @openid_ns = OPENID1_NS
    end

    def test_bad_response
      assert_log_matches('Server error when requesting an association') {
        response = call_negotiate([mk_message({})])
        assert_equal(nil, response)
      }
    end

    def test_empty_assoc_type
      msg = mk_message({'error' => 'Unsupported type',
                         'error_code' => 'unsupported-type',
                         'session_type' => 'new-session-type',
                       })

      assert_log_matches('Server error when requesting an association') {
        response = call_negotiate([msg])
        assert_equal(nil, response)
      }
    end

    def test_empty_session_type
      msg = mk_message({'error' => 'Unsupported type',
                         'error_code' => 'unsupported-type',
                         'assoc_type' => 'new-assoc-type',
                       })

      assert_log_matches('Server error when requesting an association') {
        response = call_negotiate([msg])
        assert_equal(nil, response)
      }
    end

    def test_not_allowed
      negotiator = AssociationNegotiator.new([])
      negotiator.instance_eval{
        @allowed_types = [['assoc_bogus', 'session_bogus']]
      }

      msg = mk_message({'error' => 'Unsupported type',
                         'error_code' => 'unsupported-type',
                         'assoc_type' => 'not-allowed',
                         'session_type' => 'not-allowed',
                       })

      assert_log_matches('Server error when requesting an association') {
        response = call_negotiate([msg])
        assert_equal(nil, response)
      }
    end

    def test_unsupported_with_retry
      msg = mk_message({'error' => 'Unsupported type',
                         'error_code' => 'unsupported-type',
                         'assoc_type' => 'HMAC-SHA1',
                         'session_type' => 'DH-SHA1',
                       })

      assoc = Association.new('handle', 'secret', Time.now, 10000, 'HMAC-SHA1')


      assert_log_matches('Server error when requesting an association') {
        response = call_negotiate([msg, assoc])
        assert_equal(nil, response)
      }
    end

    def test_valid
      assoc = Association.new('handle', 'secret', Time.now, 10000, 'HMAC-SHA1')
      assert_log_matches() {
        response = call_negotiate([assoc])
        assert_equal(assoc, response)
      }
    end
  end


  class TestExtractAssociation < Test::Unit::TestCase
    include ProtocolErrorMixin

    # An OpenID associate response (without the namespace)
    DEFAULTS = {
      'expires_in' => '1000',
      'assoc_handle' => 'a handle',
      'assoc_type' => 'a type',
      'session_type' => 'a session type',
    }

    def setup
      @assoc_manager = Consumer::AssociationManager.new(nil, nil)
    end

    # Make tests that ensure that an association response that is
    # missing required fields will raise an Message::KeyNotFound.
    #
    # According to 'Association Session Response' subsection 'Common
    # Response Parameters', the following fields are required for
    # OpenID 2.0:
    #
    #  * ns
    #  * session_type
    #  * assoc_handle
    #  * assoc_type
    #  * expires_in
    #
    # In OpenID 1, everything except 'session_type' and 'ns' are
    # required.
    MISSING_FIELD_SETS = ([["no_fields", []]] +
                          (DEFAULTS.keys.map do |f|
                             fields = DEFAULTS.keys
                             fields.delete(f)
                             ["missing_#{f}", fields]
                           end)
                          )

    [OPENID1_NS, OPENID2_NS].each do |ns|
      MISSING_FIELD_SETS.each do |name, fields|
        # OpenID 1 is allowed to be missing session_type
        if ns != OPENID1_NS and name != 'missing_session_type'
          test = lambda do
            msg = Message.new(ns)
            fields.each do |field|
              msg.set_arg(ns, field, DEFAULTS[field])
            end
            assert_raises(Message::KeyNotFound) do
              @assoc_manager.send(:extract_association, msg, nil)
            end
          end
          define_method("test_#{name}", test)
        end
      end
    end

    # assert that extracting a response that contains the given
    # response session type when the request was made for the given
    # request session type will raise a ProtocolError indicating
    # session type mismatch
    def assert_session_mismatch(req_type, resp_type, ns)
      # Create an association session that has "req_type" as its
      # session_type and no allowed_assoc_types
      assoc_session_class = Class.new do
        @session_type = req_type
        def self.session_type
          @session_type
        end
        def self.allowed_assoc_types
          []
        end
      end
      assoc_session = assoc_session_class.new

      # Build an OpenID 1 or 2 association response message that has
      # the specified association session type
      msg = Message.new(ns)
      msg.update_args(ns, DEFAULTS)
      msg.set_arg(ns, 'session_type', resp_type)

      # The request type and response type have been chosen to produce
      # a session type mismatch.
      assert_protocol_error('Session type mismatch') {
        @assoc_manager.send(:extract_association, msg, assoc_session)
      }
    end

    [['no-encryption', '', OPENID2_NS],
     ['DH-SHA1', 'no-encryption', OPENID2_NS],
     ['DH-SHA256', 'no-encryption', OPENID2_NS],
     ['no-encryption', 'DH-SHA1', OPENID2_NS],
     ['DH-SHA1', 'DH-SHA256', OPENID1_NS],
     ['DH-SHA256', 'DH-SHA1', OPENID1_NS],
     ['no-encryption', 'DH-SHA1', OPENID1_NS],
    ].each do |req_type, resp_type, ns|
      test = lambda { assert_session_mismatch(req_type, resp_type, ns) }
      name = "test_mismatch_req_#{req_type}_resp_#{resp_type}_#{ns}"
      define_method(name, test)
    end

    def test_openid1_no_encryption_fallback
      # A DH-SHA1 session
      assoc_session = Consumer::DiffieHellmanSHA1Session.new

      # An OpenID 1 no-encryption association response
      msg = Message.from_openid_args({
                                       'expires_in' => '1000',
                                       'assoc_handle' => 'a handle',
                                       'assoc_type' => 'HMAC-SHA1',
                                       'mac_key' => 'X' * 20,
                                     })

      # Should succeed
      assoc = @assoc_manager.send(:extract_association, msg, assoc_session)
      assert_equal('a handle', assoc.handle)
      assert_equal('HMAC-SHA1', assoc.assoc_type)
      assert(assoc.expires_in.between?(999, 1000))
      assert('X' * 20, assoc.secret)
    end
  end

  class GetOpenIDSessionTypeTest < Test::Unit::TestCase
    include TestUtil

    SERVER_URL = 'http://invalid/'

    def do_test(expected_session_type, session_type_value)
      # Create a Message with just 'session_type' in it, since
      # that's all this function will use. 'session_type' may be
      # absent if it's set to None.
      args = {}
      if !session_type_value.nil?
        args['session_type'] = session_type_value
      end
      message = Message.from_openid_args(args)
      assert(message.is_openid1)

      assoc_manager = Consumer::AssociationManager.new(nil, SERVER_URL)
      actual_session_type = assoc_manager.send(:get_openid1_session_type,
                                               message)
      error_message = ("Returned session type parameter #{session_type_value}"\
                       "was expected to yield session type "\
                       "#{expected_session_type}, but yielded "\
                       "#{actual_session_type}")
      assert_equal(expected_session_type, actual_session_type, error_message)
    end


    [['nil', 'no-encryption', nil],
     ['empty', 'no-encryption', ''],
     ['dh_sha1', 'DH-SHA1', 'DH-SHA1'],
     ['dh_sha256', 'DH-SHA256', 'DH-SHA256'],
    ].each {|name, expected, input|
      # Define a test method that will check what session type will be
      # used if the OpenID 1 response to an associate call sets the
      # 'session_type' field to `session_type_value`
      test = lambda {assert_log_matches() { do_test(expected, input) } }
      define_method("test_#{name}", &test)
    }

    # This one's different because it expects log messages
    def test_explicit_no_encryption
      assert_log_matches("WARNING: #{SERVER_URL} sent 'no-encryption'"){
        do_test('no-encryption', 'no-encryption')
      }
    end
  end

  class ExtractAssociationTest < Test::Unit::TestCase
    include ProtocolErrorMixin

    SERVER_URL = 'http://invalid/'

    def setup
      @session_type = 'testing-session'

      # This must something that works for Association::from_expires_in
      @assoc_type = 'HMAC-SHA1'

      @assoc_handle = 'testing-assoc-handle'

      # These arguments should all be valid
      @assoc_response =
        Message.from_openid_args({
                                   'expires_in' => '1000',
                                   'assoc_handle' => @assoc_handle,
                                   'assoc_type' => @assoc_type,
                                   'session_type' => @session_type,
                                   'ns' => OPENID2_NS,
                                 })
      assoc_session_cls = Class.new do
        class << self
          attr_accessor :allowed_assoc_types, :session_type
        end

        attr_reader :extract_secret_called, :secret
        def initialize
          @extract_secret_called = false
          @secret = 'shhhhh!'
        end

        def extract_secret(_)
          @extract_secret_called = true
          @secret
        end
      end
      @assoc_session = assoc_session_cls.new
      @assoc_session.class.allowed_assoc_types = [@assoc_type]
      @assoc_session.class.session_type = @session_type

      @assoc_manager = Consumer::AssociationManager.new(nil, SERVER_URL)
    end

    def call_extract
      @assoc_manager.send(:extract_association,
                          @assoc_response, @assoc_session)
    end

    # Handle a full successful association response
    def test_works_with_good_fields
      assoc = call_extract
      assert(@assoc_session.extract_secret_called)
      assert_equal(@assoc_session.secret, assoc.secret)
      assert_equal(1000, assoc.lifetime)
      assert_equal(@assoc_handle, assoc.handle)
      assert_equal(@assoc_type, assoc.assoc_type)
    end

    def test_bad_assoc_type
      # Make sure that the assoc type in the response is not valid
      # for the given session.
      @assoc_session.class.allowed_assoc_types = []
      assert_protocol_error('Unsupported assoc_type for sess') {call_extract}
    end

    def test_bad_expires_in
      # Invalid value for expires_in should cause failure
      @assoc_response.set_arg(OPENID_NS, 'expires_in', 'forever')
      assert_protocol_error('Invalid expires_in') {call_extract}
    end
  end

  class TestExtractAssociationDiffieHellman < Test::Unit::TestCase
    include ProtocolErrorMixin

    SECRET = 'x' * 20

    def setup
      @assoc_manager = Consumer::AssociationManager.new(nil, nil)
    end

    def setup_dh
      sess, message = @assoc_manager.send(:create_associate_request,
                                          'HMAC-SHA1', 'DH-SHA1')

      server_dh = DiffieHellman.new
      cons_dh = sess.instance_variable_get('@dh')

      enc_mac_key = server_dh.xor_secret(CryptUtil.method(:sha1),
                                         cons_dh.public, SECRET)

      server_resp = {
        'dh_server_public' => CryptUtil.num_to_base64(server_dh.public),
        'enc_mac_key' => Util.to_base64(enc_mac_key),
        'assoc_type' => 'HMAC-SHA1',
        'assoc_handle' => 'handle',
        'expires_in' => '1000',
        'session_type' => 'DH-SHA1',
      }
      if @assoc_manager.instance_variable_get(:@compatibility_mode)
        server_resp['ns'] = OPENID2_NS
      end
      return [sess, Message.from_openid_args(server_resp)]
    end

    def test_success
      sess, server_resp = setup_dh
      ret = @assoc_manager.send(:extract_association, server_resp, sess)
      assert(!ret.nil?)
      assert_equal(ret.assoc_type, 'HMAC-SHA1')
      assert_equal(ret.secret, SECRET)
      assert_equal(ret.handle, 'handle')
      assert_equal(ret.lifetime, 1000)
    end

    def test_openid2success
      # Use openid 1 type in endpoint so _setUpDH checks
      # compatibility mode state properly
      @assoc_manager.instance_variable_set('@compatibility_mode', true)
      test_success()
    end

    def test_bad_dh_values
      sess, server_resp = setup_dh
      server_resp.set_arg(OPENID_NS, 'enc_mac_key', '\x00\x00\x00')
      assert_protocol_error('Malformed response for') {
        @assoc_manager.send(:extract_association, server_resp, sess)
      }
    end
  end

  class TestAssocManagerGetAssociation < Test::Unit::TestCase
    include FetcherMixin
    include TestUtil

    attr_reader :negotiate_association

    def setup
      @server_url = 'http://invalid/'
      @store = Store::Memory.new
      @assoc_manager = Consumer::AssociationManager.new(@store, @server_url)
      @assoc_manager.extend(Const)
      @assoc = Association.new('handle', 'secret', Time.now, 10000,
                               'HMAC-SHA1')
    end

    def set_negotiate_response(assoc)
      @assoc_manager.const(:negotiate_association, assoc)
    end

    def test_not_in_store_no_response
      set_negotiate_response(nil)
      assert_equal(nil, @assoc_manager.get_association)
    end

    def test_not_in_store_negotiate_assoc
      # Not stored beforehand:
      stored_assoc = @store.get_association(@server_url, @assoc.handle)
      assert_equal(nil, stored_assoc)

      # Returned from associate call:
      set_negotiate_response(@assoc)
      assert_equal(@assoc, @assoc_manager.get_association)

      # It should have been stored:
      stored_assoc = @store.get_association(@server_url, @assoc.handle)
      assert_equal(@assoc, stored_assoc)
    end

    def test_in_store_no_response
      set_negotiate_response(nil)
      @store.store_association(@server_url, @assoc)
      assert_equal(@assoc, @assoc_manager.get_association)
    end

    def test_request_assoc_with_status_error
      fetcher_class = Class.new do
        define_method(:fetch) do |*args|
          MockResponse.new(500, '')
        end
      end
      with_fetcher(fetcher_class.new) do
        assert_log_matches('Got HTTP status error when requesting') {
          result = @assoc_manager.send(:request_association, 'HMAC-SHA1',
                                       'no-encryption')
          assert(result.nil?)
        }
      end
    end
  end

  class TestAssocManagerRequestAssociation < Test::Unit::TestCase
    include FetcherMixin
    include TestUtil

    def setup
      @assoc_manager = Consumer::AssociationManager.new(nil, 'http://invalid/')
      @assoc_type = 'HMAC-SHA1'
      @session_type = 'no-encryption'
      @message = Message.new(OPENID2_NS)
      @message.update_args(OPENID_NS, {
                             'assoc_type' => @assoc_type,
                             'session_type' => @session_type,
                             'assoc_handle' => 'kaboodle',
                             'expires_in' => '1000',
                             'mac_key' => 'X' * 20,
                           })
    end

    def make_request
      kv = @message.to_kvform
      fetcher_class = Class.new do
        define_method(:fetch) do |*args|
          MockResponse.new(200, kv)
        end
      end
      with_fetcher(fetcher_class.new) do
        @assoc_manager.send(:request_association, @assoc_type, @session_type)
      end
    end

    # The association we get is from valid processing of our result,
    # and that no errors are raised
    def test_success
      assert_equal('kaboodle', make_request.handle)
    end

    # A missing parameter gets translated into a log message and
    # causes the method to return nil
    def test_missing_fields
      @message.del_arg(OPENID_NS, 'assoc_type')
      assert_log_matches('Missing required par') {
        assert_equal(nil, make_request)
      }
    end

    # A bad value results in a log message and causes the method to
    # return nil
    def test_protocol_error
      @message.set_arg(OPENID_NS, 'expires_in', 'goats')
      assert_log_matches('Protocol error processing') {
        assert_equal(nil, make_request)
      }
    end
  end

end
