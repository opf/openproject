require 'openid/extensions/pape'
require 'openid/message'
require 'openid/server'
require 'openid/consumer/responses'

module OpenID
  module PAPETest
    class PapeRequestTestCase < Test::Unit::TestCase
      def setup
        @req = PAPE::Request.new
      end

      def test_construct
        assert_equal([], @req.preferred_auth_policies)
        assert_equal(nil, @req.max_auth_age)
        assert_equal('pape', @req.ns_alias)

        req2 = PAPE::Request.new([PAPE::AUTH_MULTI_FACTOR], 1000)
        assert_equal([PAPE::AUTH_MULTI_FACTOR], req2.preferred_auth_policies)
        assert_equal(1000, req2.max_auth_age)
      end

      def test_add_policy_uri
        assert_equal([], @req.preferred_auth_policies)
        @req.add_policy_uri(PAPE::AUTH_MULTI_FACTOR)
        assert_equal([PAPE::AUTH_MULTI_FACTOR], @req.preferred_auth_policies)
        @req.add_policy_uri(PAPE::AUTH_MULTI_FACTOR)
        assert_equal([PAPE::AUTH_MULTI_FACTOR], @req.preferred_auth_policies)
        @req.add_policy_uri(PAPE::AUTH_PHISHING_RESISTANT)
        assert_equal([PAPE::AUTH_MULTI_FACTOR, PAPE::AUTH_PHISHING_RESISTANT], @req.preferred_auth_policies)
        @req.add_policy_uri(PAPE::AUTH_MULTI_FACTOR)
        assert_equal([PAPE::AUTH_MULTI_FACTOR, PAPE::AUTH_PHISHING_RESISTANT], @req.preferred_auth_policies)
      end

      def test_get_extension_args
        assert_equal({'preferred_auth_policies' => ''}, @req.get_extension_args)
        @req.add_policy_uri('http://uri')
        assert_equal({'preferred_auth_policies' => 'http://uri'}, @req.get_extension_args)
        @req.add_policy_uri('http://zig')
        assert_equal({'preferred_auth_policies' => 'http://uri http://zig'}, @req.get_extension_args)
        @req.max_auth_age = 789
        assert_equal({'preferred_auth_policies' => 'http://uri http://zig', 'max_auth_age' => '789'}, @req.get_extension_args)
      end

      def test_parse_extension_args
        args = {'preferred_auth_policies' => 'http://foo http://bar',
                'max_auth_age' => '9'}
        @req.parse_extension_args(args)
        assert_equal(9, @req.max_auth_age)
        assert_equal(['http://foo','http://bar'], @req.preferred_auth_policies)
      end

      def test_parse_extension_args_empty
        @req.parse_extension_args({})
        assert_equal(nil, @req.max_auth_age)
        assert_equal([], @req.preferred_auth_policies)
      end

      def test_from_openid_request
        openid_req_msg = Message.from_openid_args({
          'mode' => 'checkid_setup',
          'ns' => OPENID2_NS,
          'ns.pape' => PAPE::NS_URI,
          'pape.preferred_auth_policies' => [PAPE::AUTH_MULTI_FACTOR, PAPE::AUTH_PHISHING_RESISTANT].join(' '),
          'pape.max_auth_age' => '5476'
          })
        oid_req = Server::OpenIDRequest.new
        oid_req.message = openid_req_msg
        req = PAPE::Request.from_openid_request(oid_req)
        assert_equal([PAPE::AUTH_MULTI_FACTOR, PAPE::AUTH_PHISHING_RESISTANT], req.preferred_auth_policies)
        assert_equal(5476, req.max_auth_age)
      end

      def test_from_openid_request_no_pape
        message = Message.new
        openid_req = Server::OpenIDRequest.new
        openid_req.message = message
        pape_req = PAPE::Request.from_openid_request(openid_req)
        assert(pape_req.nil?)
      end

      def test_preferred_types
        @req.add_policy_uri(PAPE::AUTH_PHISHING_RESISTANT)
        @req.add_policy_uri(PAPE::AUTH_MULTI_FACTOR)
        pt = @req.preferred_types([PAPE::AUTH_MULTI_FACTOR,
                                   PAPE::AUTH_MULTI_FACTOR_PHYSICAL])
        assert_equal([PAPE::AUTH_MULTI_FACTOR], pt)
      end
    end

    class DummySuccessResponse
      attr_accessor :message

      def initialize(message, signed_stuff)
        @message = message
        @signed_stuff = signed_stuff
      end

      def get_signed_ns(ns_uri)
        return @signed_stuff
      end

    end

    class PapeResponseTestCase < Test::Unit::TestCase
      def setup
        @req = PAPE::Response.new
      end

      def test_construct
        assert_equal([], @req.auth_policies)
        assert_equal(nil, @req.auth_time)
        assert_equal('pape', @req.ns_alias)
        assert_equal(nil, @req.nist_auth_level)

        req2 = PAPE::Response.new([PAPE::AUTH_MULTI_FACTOR], "1983-11-05T12:30:24Z", 3)
        assert_equal([PAPE::AUTH_MULTI_FACTOR], req2.auth_policies)
        assert_equal("1983-11-05T12:30:24Z", req2.auth_time)
        assert_equal(3, req2.nist_auth_level)
      end

      def test_add_policy_uri
        assert_equal([], @req.auth_policies)
        @req.add_policy_uri(PAPE::AUTH_MULTI_FACTOR)
        assert_equal([PAPE::AUTH_MULTI_FACTOR], @req.auth_policies)
        @req.add_policy_uri(PAPE::AUTH_MULTI_FACTOR)
        assert_equal([PAPE::AUTH_MULTI_FACTOR], @req.auth_policies)
        @req.add_policy_uri(PAPE::AUTH_PHISHING_RESISTANT)
        assert_equal([PAPE::AUTH_MULTI_FACTOR, PAPE::AUTH_PHISHING_RESISTANT], @req.auth_policies)
        @req.add_policy_uri(PAPE::AUTH_MULTI_FACTOR)
        assert_equal([PAPE::AUTH_MULTI_FACTOR, PAPE::AUTH_PHISHING_RESISTANT], @req.auth_policies)
      end

      def test_get_extension_args
        assert_equal({'auth_policies' => 'none'}, @req.get_extension_args)
        @req.add_policy_uri('http://uri')
        assert_equal({'auth_policies' => 'http://uri'}, @req.get_extension_args)
        @req.add_policy_uri('http://zig')
        assert_equal({'auth_policies' => 'http://uri http://zig'}, @req.get_extension_args)
        @req.auth_time =  "1983-11-05T12:30:24Z"
        assert_equal({'auth_policies' => 'http://uri http://zig', 'auth_time' => "1983-11-05T12:30:24Z"}, @req.get_extension_args)
        @req.nist_auth_level = 3
        assert_equal({'auth_policies' => 'http://uri http://zig', 'auth_time' => "1983-11-05T12:30:24Z", 'nist_auth_level' => '3'}, @req.get_extension_args)
      end

      def test_get_extension_args_error_auth_age
        @req.auth_time = "the beginning of time"
        assert_raises(ArgumentError) { @req.get_extension_args }
      end

      def test_get_extension_args_error_nist_auth_level
        @req.nist_auth_level = "high as a kite"
        assert_raises(ArgumentError) { @req.get_extension_args }
        @req.nist_auth_level = 5
        assert_raises(ArgumentError) { @req.get_extension_args }
        @req.nist_auth_level = -1
        assert_raises(ArgumentError) { @req.get_extension_args }
      end

      def test_parse_extension_args
        args = {'auth_policies' => 'http://foo http://bar',
                'auth_time' => '1983-11-05T12:30:24Z'}
        @req.parse_extension_args(args)
        assert_equal('1983-11-05T12:30:24Z', @req.auth_time)
        assert_equal(['http://foo','http://bar'], @req.auth_policies)
      end

      def test_parse_extension_args_empty
        @req.parse_extension_args({})
        assert_equal(nil, @req.auth_time)
        assert_equal([], @req.auth_policies)
      end
      
      def test_parse_extension_args_strict_bogus1
        args = {'auth_policies' => 'http://foo http://bar',
                'auth_time' => 'this one time'}
        assert_raises(ArgumentError) { 
          @req.parse_extension_args(args, true)
        }
      end

      def test_parse_extension_args_strict_bogus2
        args = {'auth_policies' => 'http://foo http://bar',
                'auth_time' => '1983-11-05T12:30:24Z',
                'nist_auth_level' => 'some'}
        assert_raises(ArgumentError) { 
          @req.parse_extension_args(args, true)
        }
      end
      
      def test_parse_extension_args_strict_good
        args = {'auth_policies' => 'http://foo http://bar',
                'auth_time' => '2007-10-11T05:25:18Z',
                'nist_auth_level' => '0'}
        @req.parse_extension_args(args, true)
        assert_equal(['http://foo','http://bar'], @req.auth_policies)
        assert_equal('2007-10-11T05:25:18Z', @req.auth_time)
        assert_equal(0, @req.nist_auth_level)
      end

      def test_parse_extension_args_nostrict_bogus
        args = {'auth_policies' => 'http://foo http://bar',
                'auth_time' => 'some time ago',
                'nist_auth_level' => 'some'}
        @req.parse_extension_args(args)
        assert_equal(['http://foo','http://bar'], @req.auth_policies)
        assert_equal(nil, @req.auth_time)
        assert_equal(nil, @req.nist_auth_level)
      end

      
      def test_from_success_response
        
        openid_req_msg = Message.from_openid_args({
          'mode' => 'id_res',
          'ns' => OPENID2_NS,
          'ns.pape' => PAPE::NS_URI,
          'pape.auth_policies' => [PAPE::AUTH_MULTI_FACTOR, PAPE::AUTH_PHISHING_RESISTANT].join(' '),
          'pape.auth_time' => '1983-11-05T12:30:24Z'
          })
        signed_stuff = {
          'auth_policies' => [PAPE::AUTH_MULTI_FACTOR, PAPE::AUTH_PHISHING_RESISTANT].join(' '),
          'auth_time' => '1983-11-05T12:30:24Z'
        }
        oid_req = DummySuccessResponse.new(openid_req_msg, signed_stuff)
        req = PAPE::Response.from_success_response(oid_req)
        assert_equal([PAPE::AUTH_MULTI_FACTOR, PAPE::AUTH_PHISHING_RESISTANT], req.auth_policies)
        assert_equal('1983-11-05T12:30:24Z', req.auth_time)
      end

      def test_from_success_response_unsigned
        openid_req_msg = Message.from_openid_args({
          'mode' => 'id_res',
          'ns' => OPENID2_NS,
          'ns.pape' => PAPE::NS_URI,
          'pape.auth_policies' => [PAPE::AUTH_MULTI_FACTOR, PAPE::AUTH_PHISHING_RESISTANT].join(' '),
          'pape.auth_time' => '1983-11-05T12:30:24Z'
          })
        signed_stuff = {}
        endpoint = OpenIDServiceEndpoint.new
        oid_req = Consumer::SuccessResponse.new(endpoint, openid_req_msg, signed_stuff)
        req = PAPE::Response.from_success_response(oid_req)
        assert(req.nil?, req.inspect)
      end
    end
  end
end
