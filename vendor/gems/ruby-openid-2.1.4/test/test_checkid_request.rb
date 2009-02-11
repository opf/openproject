require "openid/consumer/checkid_request"
require "openid/message"
require "test/unit"
require "testutil"
require "util"

module OpenID
  class Consumer
    class CheckIDRequest
      class DummyEndpoint
        attr_accessor :preferred_namespace, :local_id, :server_url,
          :is_op_identifier, :claimed_id

        def initialize
          @preferred_namespace = nil
          @local_id = nil
          @server_url = nil
          @is_op_identifier = false
        end

        def get_local_id
          @local_id
        end

        def compatibility_mode
          @preferred_namespace == OPENID1_NS
        end
      end

      module CheckIDTestMixin
        include TestUtil

        def setup
          @endpoint = DummyEndpoint.new
          @endpoint.local_id = 'http://server.unittest/joe'
          @endpoint.claimed_id = 'http://joe.vanity.example/'
          @endpoint.server_url = 'http://server.unittest/'
          @endpoint.preferred_namespace = preferred_namespace
          @realm = 'http://example/'
          @return_to = 'http://example/return/'
          @assoc = GoodAssoc.new
          @checkid_req = CheckIDRequest.new(@assoc, @endpoint)
        end

        def assert_has_identifiers(msg, local_id, claimed_id)
          assert_openid_value_equal(msg, 'identity', local_id)
          assert_openid_value_equal(msg, 'claimed_id', claimed_id)
        end

        def assert_openid_key_exists(msg, key)
          assert(msg.get_arg(OPENID_NS, key),
                 "#{key} not present in #{msg.get_args(OPENID_NS).inspect}")
        end

        def assert_openid_key_absent(msg, key)
          assert(msg.get_arg(OPENID_NS, key).nil?)
        end

        def assert_openid_value_equal(msg, key, expected)
          actual = msg.get_arg(OPENID_NS, key, NO_DEFAULT)
          error_text = ("Expected #{expected.inspect} for openid.#{key} "\
                        "but got #{actual.inspect}: #{msg.inspect}")
          assert_equal(expected, actual, error_text)
        end

        def assert_anonymous(msg)
          ['claimed_id', 'identity'].each do |key|
            assert_openid_key_absent(msg, key)
          end
        end

        def assert_has_required_fields(msg)
          internal_message = @checkid_req.instance_variable_get(:@message)
          assert_equal(preferred_namespace,
                       internal_message.get_openid_namespace)

          assert_equal(preferred_namespace, msg.get_openid_namespace)
          assert_openid_value_equal(msg, 'mode', expected_mode)

          # Implement these in subclasses because they depend on
          # protocol differences!
          assert_has_realm(msg)
          assert_identifiers_present(msg)
        end

        # TESTS

        def test_check_no_assoc_handle
          @checkid_req.instance_variable_set('@assoc', nil)
          msg = assert_log_matches("Generated checkid") {
            @checkid_req.get_message(@realm, @return_to, immediate)
          }
          assert_openid_key_absent(msg, 'assoc_handle')
        end

        def test_check_with_assoc_handle
          msg = assert_log_matches("Generated checkid") {
            @checkid_req.get_message(@realm, @return_to, immediate)
          }

          assert_openid_value_equal(msg, 'assoc_handle', @assoc.handle)
        end

        def test_add_extension_arg
          @checkid_req.add_extension_arg('bag:', 'color', 'brown')
          @checkid_req.add_extension_arg('bag:', 'material', 'paper')
          assert(@checkid_req.message.namespaces.member?('bag:'))
          assert_equal(@checkid_req.message.get_args('bag:'),
                       {'color' => 'brown', 'material' => 'paper'})

          msg = assert_log_matches("Generated checkid") {
            @checkid_req.get_message(@realm, @return_to, immediate)
          }

          # XXX: this depends on the way that Message assigns
          # namespaces. Really it doesn't care that it has alias "0",
          # but that is tested anyway
          post_args = msg.to_post_args()
          assert_equal('brown', post_args['openid.ext0.color'])
          assert_equal('paper', post_args['openid.ext0.material'])
        end

        def test_standard
          msg = assert_log_matches('Generated checkid') {
            @checkid_req.get_message(@realm, @return_to, immediate)
          }
          assert_has_identifiers(msg, @endpoint.local_id, @endpoint.claimed_id)
        end

        def test_send_redirect?
          silence_logging {
            url = @checkid_req.redirect_url(@realm, @return_to, immediate)
            assert(url.length < OPENID1_URL_LIMIT)
            assert(@checkid_req.send_redirect?(@realm, @return_to, immediate))

            @return_to << '/foo' * 1000
            url = @checkid_req.redirect_url(@realm, @return_to, immediate)
            assert(url.length > OPENID1_URL_LIMIT)
            actual = @checkid_req.send_redirect?(@realm, @return_to, immediate)
            expected = preferred_namespace != OPENID2_NS
            assert_equal(expected, actual)
          }
        end
      end

      class TestCheckIDRequestOpenID2 < Test::Unit::TestCase
        include CheckIDTestMixin

        def immediate
          false
        end

        def expected_mode
          'checkid_setup'
        end

        def preferred_namespace
          OPENID2_NS
        end

        # check presence of proper realm key and absence of the wrong
        # one.
        def assert_has_realm(msg)
          assert_openid_value_equal(msg, 'realm', @realm)
          assert_openid_key_absent(msg, 'trust_root')
        end

        def assert_identifiers_present(msg)
          identity_present = msg.has_key?(OPENID_NS, 'identity')
          claimed_present = msg.has_key?(OPENID_NS, 'claimed_id')

          assert_equal(claimed_present, identity_present)
        end

        # OpenID Checkid_Requests should be able to set 'anonymous' to true.
        def test_set_anonymous_works_for_openid2
          assert(@checkid_req.message.is_openid2)
          assert_nothing_raised {@checkid_req.anonymous = true}
          assert_nothing_raised {@checkid_req.anonymous = false}
        end

        def test_user_anonymous_ignores_identfier
          @checkid_req.anonymous = true
          msg = assert_log_matches('Generated checkid') {
            @checkid_req.get_message(@realm, @return_to, immediate)
          }
          assert_has_required_fields(msg)
          assert_anonymous(msg)
        end

        def test_op_anonymous_ignores_identifier
          @endpoint.is_op_identifier = true
          @checkid_req.anonymous = true
          msg = assert_log_matches('Generated checkid') {
            @checkid_req.get_message(@realm, @return_to, immediate)
          }
          assert_has_required_fields(msg)
          assert_anonymous(msg)
        end

        def test_op_identifier_sends_identifier_select
          @endpoint.is_op_identifier = true
          msg = assert_log_matches('Generated checkid') {
            @checkid_req.get_message(@realm, @return_to, immediate)
          }
          assert_has_required_fields(msg)
          assert_has_identifiers(msg, IDENTIFIER_SELECT, IDENTIFIER_SELECT)
        end
      end

      class TestCheckIDRequestOpenID1 < Test::Unit::TestCase
        include CheckIDTestMixin

        def immediate
          false
        end

        def preferred_namespace
          OPENID1_NS
        end

        def expected_mode
          'checkid_setup'
        end

        # Make sure claimed_is is *absent* in request.
        def assert_has_identifiers(msg, op_specific_id, claimed_id)
          assert_openid_value_equal(msg, 'identity', op_specific_id)
          assert_openid_key_absent(msg, 'claimed_id')
        end

        def assert_identifiers_present(msg)
          assert_openid_key_absent(msg, 'claimed_id')
          assert(msg.has_key?(OPENID_NS, 'identity'))
        end

        # check presence of proper realm key and absence of the wrong
        # one.
        def assert_has_realm(msg)
          assert_openid_value_equal(msg, 'trust_root', @realm)
          assert_openid_key_absent(msg, 'realm')
        end

        # TESTS

        # OpenID 1 requests MUST NOT be able to set anonymous to true
        def test_set_anonymous_fails_for_openid1
          assert(@checkid_req.message.is_openid1)
          assert_raises(ArgumentError) {
            @checkid_req.anonymous = true
          }
          assert_nothing_raised{
            @checkid_req.anonymous = false
          }
        end

        # Identfier select SHOULD NOT be sent, but this pathway is in
        # here in case some special discovery stuff is done to trigger
        # it with OpenID 1. If it is triggered, it will send
        # identifier_select just like OpenID 2.
        def test_identifier_select
          @endpoint.is_op_identifier = true
          msg = assert_log_matches('Generated checkid') {
            @checkid_req.get_message(@realm, @return_to, immediate)
          }
          assert_has_required_fields(msg)
          assert_equal(IDENTIFIER_SELECT,
                       msg.get_arg(OPENID1_NS, 'identity'))
        end

      end

      class TestCheckIDRequestOpenID1Immediate < TestCheckIDRequestOpenID1
        def immediate
          true
        end

        def expected_mode
          'checkid_immediate'
        end
      end

      class TestCheckid_RequestOpenID2Immediate < TestCheckIDRequestOpenID2
        def immediate
          true
        end

        def expected_mode
          'checkid_immediate'
        end
      end
    end
  end
end
