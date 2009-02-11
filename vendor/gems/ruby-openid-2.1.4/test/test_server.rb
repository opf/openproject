require 'openid/server'
require 'openid/cryptutil'
require 'openid/association'
require 'openid/util'
require 'openid/message'
require 'openid/store/memory'
require 'openid/dh'
require 'openid/consumer/associationmanager'
require 'util'
require "testutil"

require 'test/unit'
require 'uri'

# In general, if you edit or add tests here, try to move in the
# direction of testing smaller units.  For testing the external
# interfaces, we'll be developing an implementation-agnostic testing
# suite.

# for more, see /etc/ssh/moduli

module OpenID

  ALT_MODULUS = 0xCAADDDEC1667FC68B5FA15D53C4E1532DD24561A1A2D47A12C01ABEA1E00731F6921AAC40742311FDF9E634BB7131BEE1AF240261554389A910425E044E88C8359B010F5AD2B80E29CB1A5B027B19D9E01A6F63A6F45E5D7ED2FF6A2A0085050A7D0CF307C3DB51D2490355907B4427C23A98DF1EB8ABEF2BA209BB7AFFE86A7
  ALT_GEN = 5

  class CatchLogs
    def catchlogs_setup
      @old_logger = Util.logger
      Util.logger = self.method('got_log_message')
      @messages = []
    end

    def got_log_message(message)
      @messages << message
    end

    def teardown
      Util.logger = @old_logger
    end
  end

  class TestProtocolError < Test::Unit::TestCase
    def test_browserWithReturnTo
      return_to = "http://rp.unittest/consumer"
      # will be a ProtocolError raised by Decode or
      # CheckIDRequest.answer
      args = Message.from_post_args({
                                      'openid.mode' => 'monkeydance',
                                      'openid.identity' => 'http://wagu.unittest/',
                                      'openid.return_to' => return_to,
                                    })
      e = Server::ProtocolError.new(args, "plucky")
      assert(e.has_return_to)
      expected_args = {
        'openid.mode' => 'error',
        'openid.error' => 'plucky',
      }

      rt_base, result_args = e.encode_to_url.split('?', 2)
      result_args = Util.parse_query(result_args)
      assert_equal(result_args, expected_args)
    end

    def test_browserWithReturnTo_OpenID2_GET
      return_to = "http://rp.unittest/consumer"
      # will be a ProtocolError raised by Decode or
      # CheckIDRequest.answer
      args = Message.from_post_args({
                                      'openid.ns' => OPENID2_NS,
                                      'openid.mode' => 'monkeydance',
                                      'openid.identity' => 'http://wagu.unittest/',
                                      'openid.claimed_id' => 'http://wagu.unittest/',
                                      'openid.return_to' => return_to,
                                    })
      e = Server::ProtocolError.new(args, "plucky")
      assert(e.has_return_to)
      expected_args = {
        'openid.ns' => OPENID2_NS,
        'openid.mode' => 'error',
        'openid.error' => 'plucky',
      }

      rt_base, result_args = e.encode_to_url.split('?', 2)
      result_args = Util.parse_query(result_args)
      assert_equal(result_args, expected_args)
    end

    def test_browserWithReturnTo_OpenID2_POST
      return_to = "http://rp.unittest/consumer" + ('x' * OPENID1_URL_LIMIT)
      # will be a ProtocolError raised by Decode or
      # CheckIDRequest.answer
      args = Message.from_post_args({
                                      'openid.ns' => OPENID2_NS,
                                      'openid.mode' => 'monkeydance',
                                      'openid.identity' => 'http://wagu.unittest/',
                                      'openid.claimed_id' => 'http://wagu.unittest/',
                                      'openid.return_to' => return_to,
                                    })
      e = Server::ProtocolError.new(args, "plucky")
      assert(e.has_return_to)
      expected_args = {
        'openid.ns' => OPENID2_NS,
        'openid.mode' => 'error',
        'openid.error' => 'plucky',
      }

      assert(e.which_encoding == Server::ENCODE_HTML_FORM)
      assert(e.to_form_markup == e.to_message.to_form_markup(
                                                             args.get_arg(OPENID_NS, 'return_to')))
    end

    def test_browserWithReturnTo_OpenID1_exceeds_limit
      return_to = "http://rp.unittest/consumer" + ('x' * OPENID1_URL_LIMIT)
      # will be a ProtocolError raised by Decode or
      # CheckIDRequest.answer
      args = Message.from_post_args({
                                      'openid.mode' => 'monkeydance',
                                      'openid.identity' => 'http://wagu.unittest/',
                                      'openid.return_to' => return_to,
                                    })
      e = Server::ProtocolError.new(args, "plucky")
      assert(e.has_return_to)
      expected_args = {
        'openid.mode' => 'error',
        'openid.error' => 'plucky',
      }

      assert(e.which_encoding == Server::ENCODE_URL)

      rt_base, result_args = e.encode_to_url.split('?', 2)
      result_args = Util.parse_query(result_args)
      assert_equal(result_args, expected_args)
    end

    def test_noReturnTo
      # will be a ProtocolError raised by Decode or
      # CheckIDRequest.answer
      args = Message.from_post_args({
                                      'openid.mode' => 'zebradance',
                                      'openid.identity' => 'http://wagu.unittest/',
                                    })
      e = Server::ProtocolError.new(args, "waffles")
      assert(!e.has_return_to)
      expected = "error:waffles\nmode:error\n"
      assert_equal(e.encode_to_kvform, expected)
    end

    def test_no_message
      e = Server::ProtocolError.new(nil, "no message")
      assert(e.get_return_to.nil?)
      assert_equal(e.which_encoding, nil)
    end

    def test_which_encoding_no_message
      e = Server::ProtocolError.new(nil, "no message")
      assert(e.which_encoding.nil?)
    end
  end

  class TestDecode < Test::Unit::TestCase
    def setup
      @claimed_id = 'http://de.legating.de.coder.unittest/'
      @id_url = "http://decoder.am.unittest/"
      @rt_url = "http://rp.unittest/foobot/?qux=zam"
      @tr_url = "http://rp.unittest/"
      @assoc_handle = "{assoc}{handle}"
      @op_endpoint = 'http://endpoint.unittest/encode'
      @store = Store::Memory.new()
      @server = Server::Server.new(@store, @op_endpoint)
      @decode = Server::Decoder.new(@server).method('decode')
    end

    def test_none
      args = {}
      r = @decode.call(args)
      assert_equal(r, nil)
    end

    def test_irrelevant
      args = {
        'pony' => 'spotted',
        'sreg.mutant_power' => 'decaffinator',
      }
      assert_raise(Server::ProtocolError) {
        @decode.call(args)
      }
    end

    def test_bad
      args = {
        'openid.mode' => 'twos-compliment',
        'openid.pants' => 'zippered',
      }
      assert_raise(Server::ProtocolError) {
        @decode.call(args)
      }
    end

    def test_dictOfLists
      args = {
        'openid.mode' => ['checkid_setup'],
        'openid.identity' => @id_url,
        'openid.assoc_handle' => @assoc_handle,
        'openid.return_to' => @rt_url,
        'openid.trust_root' => @tr_url,
      }
      begin
        result = @decode.call(args)
      rescue ArgumentError => err
        assert(!err.to_s.index('values').nil?, err)
      else
        flunk("Expected ArgumentError, but got result #{result}")
      end
    end

    def test_checkidImmediate
      args = {
        'openid.mode' => 'checkid_immediate',
        'openid.identity' => @id_url,
        'openid.assoc_handle' => @assoc_handle,
        'openid.return_to' => @rt_url,
        'openid.trust_root' => @tr_url,
        # should be ignored
        'openid.some.extension' => 'junk',
      }
      r = @decode.call(args)
      assert(r.is_a?(Server::CheckIDRequest))
      assert_equal(r.mode, "checkid_immediate")
      assert_equal(r.immediate, true)
      assert_equal(r.identity, @id_url)
      assert_equal(r.trust_root, @tr_url)
      assert_equal(r.return_to, @rt_url)
      assert_equal(r.assoc_handle, @assoc_handle)
    end

    def test_checkidImmediate_constructor
      r = Server::CheckIDRequest.new(@id_url, @rt_url, nil,
                                     @rt_url, true, @assoc_handle)
      assert(r.mode == 'checkid_immediate')
      assert(r.immediate)
    end

    def test_checkid_missing_return_to_and_trust_root
      args = {
        'openid.ns' => OPENID2_NS,
        'openid.mode' => 'checkid_setup',
        'openid.identity' => @id_url,
        'openid.claimed_id' => @id_url,
        'openid.assoc_handle' => @assoc_handle,
      }
      assert_raise(Server::ProtocolError) {
        m = Message.from_post_args(args)
        Server::CheckIDRequest.from_message(m, @op_endpoint)
      }
    end

    def test_checkid_id_select
      args = {
        'openid.ns' => OPENID2_NS,
        'openid.mode' => 'checkid_setup',
        'openid.identity' => IDENTIFIER_SELECT,
        'openid.claimed_id' => IDENTIFIER_SELECT,
        'openid.assoc_handle' => @assoc_handle,
        'openid.return_to' => @rt_url,
        'openid.realm' => @tr_url,
      }
      m = Message.from_post_args(args)
      req = Server::CheckIDRequest.from_message(m, @op_endpoint)
      assert(req.id_select)
    end

    def test_checkid_not_id_select
      args = {
        'openid.ns' => OPENID2_NS,
        'openid.mode' => 'checkid_setup',
        'openid.assoc_handle' => @assoc_handle,
        'openid.return_to' => @rt_url,
        'openid.realm' => @tr_url,
      }

      id_args = [
                 {'openid.claimed_id' => IDENTIFIER_SELECT,
                   'openid.identity' => 'http://bogus.com/'},

                 {'openid.claimed_id' => 'http://bogus.com/',
                   'openid.identity' => 'http://bogus.com/'},
                ]

      id_args.each { |id|
        m = Message.from_post_args(args.merge(id))
        req = Server::CheckIDRequest.from_message(m, @op_endpoint)
        assert(!req.id_select)
      }
    end

    def test_checkidSetup
      args = {
        'openid.mode' => 'checkid_setup',
        'openid.identity' => @id_url,
        'openid.assoc_handle' => @assoc_handle,
        'openid.return_to' => @rt_url,
        'openid.trust_root' => @tr_url,
      }
      r = @decode.call(args)
      assert(r.is_a?(Server::CheckIDRequest))
      assert_equal(r.mode, "checkid_setup")
      assert_equal(r.immediate, false)
      assert_equal(r.identity, @id_url)
      assert_equal(r.trust_root, @tr_url)
      assert_equal(r.return_to, @rt_url)
    end

    def test_checkidSetupOpenID2
      args = {
        'openid.ns' => OPENID2_NS,
        'openid.mode' => 'checkid_setup',
        'openid.identity' => @id_url,
        'openid.claimed_id' => @claimed_id,
        'openid.assoc_handle' => @assoc_handle,
        'openid.return_to' => @rt_url,
        'openid.realm' => @tr_url,
      }
      r = @decode.call(args)
      assert(r.is_a?(Server::CheckIDRequest))
      assert_equal(r.mode, "checkid_setup")
      assert_equal(r.immediate, false)
      assert_equal(r.identity, @id_url)
      assert_equal(r.claimed_id, @claimed_id)
      assert_equal(r.trust_root, @tr_url)
      assert_equal(r.return_to, @rt_url)
    end

    def test_checkidSetupNoClaimedIDOpenID2
      args = {
        'openid.ns' => OPENID2_NS,
        'openid.mode' => 'checkid_setup',
        'openid.identity' => @id_url,
        'openid.assoc_handle' => @assoc_handle,
        'openid.return_to' => @rt_url,
        'openid.realm' => @tr_url,
      }
      assert_raise(Server::ProtocolError) {
        @decode.call(args)
      }
    end

    def test_checkidSetupNoIdentityOpenID2
      args = {
        'openid.ns' => OPENID2_NS,
        'openid.mode' => 'checkid_setup',
        'openid.assoc_handle' => @assoc_handle,
        'openid.return_to' => @rt_url,
        'openid.realm' => @tr_url,
      }
      r = @decode.call(args)
      assert(r.is_a?(Server::CheckIDRequest))
      assert_equal(r.mode, "checkid_setup")
      assert_equal(r.immediate, false)
      assert_equal(r.identity, nil)
      assert_equal(r.trust_root, @tr_url)
      assert_equal(r.return_to, @rt_url)
    end

    def test_checkidSetupNoReturnOpenID1
      # Make sure an OpenID 1 request cannot be decoded if it lacks a
      # return_to.
      args = {
        'openid.mode' => 'checkid_setup',
        'openid.identity' => @id_url,
        'openid.assoc_handle' => @assoc_handle,
        'openid.trust_root' => @tr_url,
      }
      assert_raise(Server::ProtocolError) {
        @decode.call(args)
      }
    end

    def test_checkidSetupNoReturnOpenID2
      # Make sure an OpenID 2 request with no return_to can be decoded,
      # and make sure a response to such a request raises
      # NoReturnToError.
      args = {
        'openid.ns' => OPENID2_NS,
        'openid.mode' => 'checkid_setup',
        'openid.identity' => @id_url,
        'openid.claimed_id' => @id_url,
        'openid.assoc_handle' => @assoc_handle,
        'openid.realm' => @tr_url,
      }

      req = @decode.call(args)
      assert(req.is_a?(Server::CheckIDRequest))

      assert_raise(Server::NoReturnToError) {
        req.answer(false)
      }

      assert_raise(Server::NoReturnToError) {
        req.encode_to_url('bogus')
      }

      assert_raise(Server::NoReturnToError) {
        req.cancel_url
      }
    end

    def test_checkidSetupRealmRequiredOpenID2
      # Make sure that an OpenID 2 request which lacks return_to cannot
      # be decoded if it lacks a realm.  Spec => This value
      # (openid.realm) MUST be sent if openid.return_to is omitted.
      args = {
        'openid.ns' => OPENID2_NS,
        'openid.mode' => 'checkid_setup',
        'openid.identity' => @id_url,
        'openid.assoc_handle' => @assoc_handle,
      }
      assert_raise(Server::ProtocolError) {
        @decode.call(args)
      }
    end

    def test_checkidSetupBadReturn
      args = {
        'openid.mode' => 'checkid_setup',
        'openid.identity' => @id_url,
        'openid.assoc_handle' => @assoc_handle,
        'openid.return_to' => 'not a url',
      }
      begin
        result = @decode.call(args)
      rescue Server::ProtocolError => err
        assert(err.openid_message)
      else
        flunk("Expected ProtocolError, instead returned with #{result}")
      end
    end

    def test_checkidSetupUntrustedReturn
      args = {
        'openid.mode' => 'checkid_setup',
        'openid.identity' => @id_url,
        'openid.assoc_handle' => @assoc_handle,
        'openid.return_to' => @rt_url,
        'openid.trust_root' => 'http://not-the-return-place.unittest/',
      }
      begin
        result = @decode.call(args)
      rescue Server::UntrustedReturnURL => err
        assert(err.openid_message, err.to_s)
      else
        flunk("Expected UntrustedReturnURL, instead returned with #{result}")
      end
    end

    def test_checkidSetupUntrustedReturn_Constructor
      assert_raise(Server::UntrustedReturnURL) {
        Server::CheckIDRequest.new(@id_url, @rt_url, nil,
                                   'http://not-the-return-place.unittest/',
                                   false, @assoc_handle)
      }
    end

    def test_checkidSetupMalformedReturnURL_Constructor
      assert_raise(Server::MalformedReturnURL) {
        Server::CheckIDRequest.new(@id_url, 'bogus://return.url', nil,
                                   'http://trustroot.com/',
                                   false, @assoc_handle)
      }
    end

    def test_checkAuth
      args = {
        'openid.mode' => 'check_authentication',
        'openid.assoc_handle' => '{dumb}{handle}',
        'openid.sig' => 'sigblob',
        'openid.signed' => 'identity,return_to,response_nonce,mode',
        'openid.identity' => 'signedval1',
        'openid.return_to' => 'signedval2',
        'openid.response_nonce' => 'signedval3',
        'openid.baz' => 'unsigned',
      }
      r = @decode.call(args)
      assert(r.is_a?(Server::CheckAuthRequest))
      assert_equal(r.mode, 'check_authentication')
      assert_equal(r.sig, 'sigblob')
    end

    def test_checkAuthMissingSignature
      args = {
        'openid.mode' => 'check_authentication',
        'openid.assoc_handle' => '{dumb}{handle}',
        'openid.signed' => 'foo,bar,mode',
        'openid.foo' => 'signedval1',
        'openid.bar' => 'signedval2',
        'openid.baz' => 'unsigned',
      }
      assert_raise(Server::ProtocolError) {
        @decode.call(args)
      }
    end

    def test_checkAuthAndInvalidate
      args = {
        'openid.mode' => 'check_authentication',
        'openid.assoc_handle' => '{dumb}{handle}',
        'openid.invalidate_handle' => '[[SMART_handle]]',
        'openid.sig' => 'sigblob',
        'openid.signed' => 'identity,return_to,response_nonce,mode',
        'openid.identity' => 'signedval1',
        'openid.return_to' => 'signedval2',
        'openid.response_nonce' => 'signedval3',
        'openid.baz' => 'unsigned',
      }
      r = @decode.call(args)
      assert(r.is_a?(Server::CheckAuthRequest))
      assert_equal(r.invalidate_handle, '[[SMART_handle]]')
    end

    def test_associateDH
      args = {
        'openid.mode' => 'associate',
        'openid.session_type' => 'DH-SHA1',
        'openid.dh_consumer_public' => "Rzup9265tw==",
      }
      r = @decode.call(args)
      assert(r.is_a?(Server::AssociateRequest))
      assert_equal(r.mode, "associate")
      assert_equal(r.session.session_type, "DH-SHA1")
      assert_equal(r.assoc_type, "HMAC-SHA1")
      assert(r.session.consumer_pubkey)
    end

    def test_associateDHMissingKey
      # Trying DH assoc w/o public key
      args = {
        'openid.mode' => 'associate',
        'openid.session_type' => 'DH-SHA1',
      }
      # Using DH-SHA1 without supplying dh_consumer_public is an error.
      assert_raise(Server::ProtocolError) {
        @decode.call(args)
      }
    end

    def test_associateDHpubKeyNotB64
      args = {
        'openid.mode' => 'associate',
        'openid.session_type' => 'DH-SHA1',
        'openid.dh_consumer_public' => "donkeydonkeydonkey",
      }
      assert_raise(Server::ProtocolError) {
        @decode.call(args)
      }
    end

    def test_associateDHModGen
      # test dh with non-default but valid values for dh_modulus and
      # dh_gen
      args = {
        'openid.mode' => 'associate',
        'openid.session_type' => 'DH-SHA1',
        'openid.dh_consumer_public' => "Rzup9265tw==",
        'openid.dh_modulus' => CryptUtil.num_to_base64(ALT_MODULUS),
        'openid.dh_gen' => CryptUtil.num_to_base64(ALT_GEN) ,
      }
      r = @decode.call(args)
      assert(r.is_a?(Server::AssociateRequest))
      assert_equal(r.mode, "associate")
      assert_equal(r.session.session_type, "DH-SHA1")
      assert_equal(r.assoc_type, "HMAC-SHA1")
      assert_equal(r.session.dh.modulus, ALT_MODULUS)
      assert_equal(r.session.dh.generator, ALT_GEN)
      assert(r.session.consumer_pubkey)
    end

    def test_associateDHCorruptModGen
      # test dh with non-default but valid values for dh_modulus and
      # dh_gen
      args = {
        'openid.mode' => 'associate',
        'openid.session_type' => 'DH-SHA1',
        'openid.dh_consumer_public' => "Rzup9265tw==",
        'openid.dh_modulus' => 'pizza',
        'openid.dh_gen' => 'gnocchi',
      }
      assert_raise(Server::ProtocolError) {
        @decode.call(args)
      }
    end

    def test_associateDHMissingGen
      args = {
        'openid.mode' => 'associate',
        'openid.session_type' => 'DH-SHA1',
        'openid.dh_consumer_public' => "Rzup9265tw==",
        'openid.dh_modulus' => 'pizza',
      }
      assert_raise(Server::ProtocolError) {
        @decode.call(args)
      }
    end

    def test_associateDHMissingMod
      args = {
        'openid.mode' => 'associate',
        'openid.session_type' => 'DH-SHA1',
        'openid.dh_consumer_public' => "Rzup9265tw==",
        'openid.dh_gen' => 'pizza',
      }
      assert_raise(Server::ProtocolError) {
        @decode.call(args)
      }
    end

    #     def test_associateDHInvalidModGen(self):
    #         # test dh with properly encoded values that are not a valid
    #         #   modulus/generator combination.
    #         args = {
    #             'openid.mode': 'associate',
    #             'openid.session_type': 'DH-SHA1',
    #             'openid.dh_consumer_public': "Rzup9265tw==",
    #             'openid.dh_modulus': cryptutil.longToBase64(9),
    #             'openid.dh_gen': cryptutil.longToBase64(27) ,
    #             }
    #         self.failUnlessRaises(server.ProtocolError, self.decode, args)
    #     test_associateDHInvalidModGen.todo = "low-priority feature"

    def test_associateWeirdSession
      args = {
        'openid.mode' => 'associate',
        'openid.session_type' => 'FLCL6',
        'openid.dh_consumer_public' => "YQ==\n",
      }
      assert_raise(Server::ProtocolError) {
        @decode.call(args)
      }
    end

    def test_associatePlain
      args = {
        'openid.mode' => 'associate',
      }
      r = @decode.call(args)
      assert(r.is_a?(Server::AssociateRequest))
      assert_equal(r.mode, "associate")
      assert_equal(r.session.session_type, "no-encryption")
      assert_equal(r.assoc_type, "HMAC-SHA1")
    end

    def test_nomode
      args = {
        'openid.session_type' => 'DH-SHA1',
        'openid.dh_consumer_public' => "my public keeey",
      }
      assert_raise(Server::ProtocolError) {
        @decode.call(args)
      }
    end

    def test_invalidns
      args = {'openid.ns' => 'Vegetables',
              'openid.mode' => 'associate'}
      begin
        r = @decode.call(args)
      rescue Server::ProtocolError => err
        assert(err.openid_message)
        assert(err.to_s.index('Vegetables'))
      end
    end
  end

  class BogusEncoder < Server::Encoder
    def encode(response)
      return "BOGUS"
    end
  end

  class BogusDecoder < Server::Decoder
    def decode(query)
      return "BOGUS"
    end
  end

  class TestEncode < Test::Unit::TestCase
    def setup
      @encoder = Server::Encoder.new
      @encode = @encoder.method('encode')
      @op_endpoint = 'http://endpoint.unittest/encode'
      @store = Store::Memory.new
      @server = Server::Server.new(@store, @op_endpoint)
    end

    def test_id_res_OpenID2_GET
      # Check that when an OpenID 2 response does not exceed the OpenID
      # 1 message size, a GET response (i.e., redirect) is issued.
      request = Server::CheckIDRequest.new(
                                   'http://bombom.unittest/',
                                   'http://burr.unittest/999',
                                   @server.op_endpoint,
                                   'http://burr.unittest/',
                                   false,
                                   nil)
      request.message = Message.new(OPENID2_NS)
      response = Server::OpenIDResponse.new(request)
      response.fields = Message.from_openid_args({
                                                   'ns' => OPENID2_NS,
                                                   'mode' => 'id_res',
                                                   'identity' => request.identity,
                                                   'claimed_id' => request.identity,
                                                   'return_to' => request.return_to,
                                                 })

      assert(!response.render_as_form)
      assert(response.which_encoding == Server::ENCODE_URL)
      webresponse = @encode.call(response)
      assert(webresponse.headers.member?('location'))
    end

    def test_id_res_OpenID2_POST
      # Check that when an OpenID 2 response exceeds the OpenID 1
      # message size, a POST response (i.e., an HTML form) is returned.
      request = Server::CheckIDRequest.new(
                                   'http://bombom.unittest/',
                                   'http://burr.unittest/999',
                                   @server.op_endpoint,
                                   'http://burr.unittest/',
                                   false,
                                   nil)
      request.message = Message.new(OPENID2_NS)
      response = Server::OpenIDResponse.new(request)
      response.fields = Message.from_openid_args({
                                                   'ns' => OPENID2_NS,
                                                   'mode' => 'id_res',
                                                   'identity' => request.identity,
                                                   'claimed_id' => request.identity,
                                                   'return_to' => 'x' * OPENID1_URL_LIMIT,
                                                 })

      assert(response.render_as_form)
      assert(response.encode_to_url.length > OPENID1_URL_LIMIT)
      assert(response.which_encoding == Server::ENCODE_HTML_FORM)
      webresponse = @encode.call(response)
      assert_equal(webresponse.body, response.to_form_markup)
    end

    def test_to_form_markup
       request = Server::CheckIDRequest.new(
                                   'http://bombom.unittest/',
                                   'http://burr.unittest/999',
                                   @server.op_endpoint,
                                   'http://burr.unittest/',
                                   false,
                                   nil)
      request.message = Message.new(OPENID2_NS)
      response = Server::OpenIDResponse.new(request)
      response.fields = Message.from_openid_args({
                                                   'ns' => OPENID2_NS,
                                                   'mode' => 'id_res',
                                                   'identity' => request.identity,
                                                   'claimed_id' => request.identity,
                                                   'return_to' => 'x' * OPENID1_URL_LIMIT,
                                                 })
      form_markup = response.to_form_markup({'foo'=>'bar'})
      assert(/ foo="bar"/ =~ form_markup, form_markup)
    end

    def test_to_html
       request = Server::CheckIDRequest.new(
                                   'http://bombom.unittest/',
                                   'http://burr.unittest/999',
                                   @server.op_endpoint,
                                   'http://burr.unittest/',
                                   false,
                                   nil)
      request.message = Message.new(OPENID2_NS)
      response = Server::OpenIDResponse.new(request)
      response.fields = Message.from_openid_args({
                                                   'ns' => OPENID2_NS,
                                                   'mode' => 'id_res',
                                                   'identity' => request.identity,
                                                   'claimed_id' => request.identity,
                                                   'return_to' => 'x' * OPENID1_URL_LIMIT,
                                                 })
      html = response.to_html
      assert(html)
    end

    def test_id_res_OpenID1_exceeds_limit
      # Check that when an OpenID 1 response exceeds the OpenID 1
      # message size, a GET response is issued.  Technically, this
      # shouldn't be permitted by the library, but this test is in place
      # to preserve the status quo for OpenID 1.
      request = Server::CheckIDRequest.new(
                                   'http://bombom.unittest/',
                                   'http://burr.unittest/999',
                                   @server.op_endpoint,
                                   'http://burr.unittest/',
                                   false,
                                   nil)
      request.message = Message.new(OPENID1_NS)

      response = Server::OpenIDResponse.new(request)
      response.fields = Message.from_openid_args({
                                                   'mode' => 'id_res',
                                                   'identity' => request.identity,
                                                   'return_to' => 'x' * OPENID1_URL_LIMIT,
                                                 })

      assert(!response.render_as_form)
      assert(response.encode_to_url.length > OPENID1_URL_LIMIT)
      assert(response.which_encoding == Server::ENCODE_URL)
      webresponse = @encode.call(response)
      assert_equal(webresponse.headers['location'], response.encode_to_url)
    end

    def test_id_res
      request = Server::CheckIDRequest.new(
                                   'http://bombom.unittest/',
                                   'http://burr.unittest/999',
                                   @server.op_endpoint,
                                   'http://burr.unittest/',
                                   false, nil)
      request.message = Message.new(OPENID1_NS)
      response = Server::OpenIDResponse.new(request)
      response.fields = Message.from_openid_args({
                                                   'mode' => 'id_res',
                                                   'identity' => request.identity,
                                                   'return_to' => request.return_to,
                                                 })
      webresponse = @encode.call(response)
      assert_equal(webresponse.code, Server::HTTP_REDIRECT)
      assert(webresponse.headers.member?('location'))

      location = webresponse.headers['location']
      assert(location.starts_with?(request.return_to),
             sprintf("%s does not start with %s",
                     location, request.return_to))
      # argh.
      q2 = Util.parse_query(URI::parse(location).query)
      expected = response.fields.to_post_args
      assert_equal(q2, expected)
    end

    def test_cancel
      request = Server::CheckIDRequest.new(
                                   'http://bombom.unittest/',
                                   'http://burr.unittest/999',
                                   @server.op_endpoint,
                                   'http://burr.unittest/',
                                   false, nil)
      request.message = Message.new(OPENID2_NS)
      response = Server::OpenIDResponse.new(request)
      response.fields = Message.from_openid_args({
                                                   'mode' => 'cancel',
                                                 })
      webresponse = @encode.call(response)
      assert_equal(webresponse.code, Server::HTTP_REDIRECT)
      assert(webresponse.headers.member?('location'))
    end

    def test_cancel_to_form
      request = Server::CheckIDRequest.new(
                                   'http://bombom.unittest/',
                                   'http://burr.unittest/999',
                                   @server.op_endpoint,
                                   'http://burr.unittest/',
                                   false, nil)
      request.message = Message.new(OPENID2_NS)
      response = Server::OpenIDResponse.new(request)
      response.fields = Message.from_openid_args({
                                                   'mode' => 'cancel',
                                                 })
      form = response.to_form_markup
      assert(form.index(request.return_to))
    end

    def test_assocReply
      msg = Message.new(OPENID2_NS)
      msg.set_arg(OPENID2_NS, 'session_type', 'no-encryption')
      request = Server::AssociateRequest.from_message(msg)
      response = Server::OpenIDResponse.new(request)
      response.fields = Message.from_post_args(
                                               {'openid.assoc_handle' => "every-zig"})
      webresponse = @encode.call(response)
      body = "assoc_handle:every-zig\n"

      assert_equal(webresponse.code, Server::HTTP_OK)
      assert_equal(webresponse.headers, {})
      assert_equal(webresponse.body, body)
    end

    def test_checkauthReply
      request = Server::CheckAuthRequest.new('a_sock_monkey',
                                     'siggggg',
                                     [])
      request.message = Message.new(OPENID2_NS)
      response = Server::OpenIDResponse.new(request)
      response.fields = Message.from_openid_args({
                                                   'is_valid' => 'true',
                                                   'invalidate_handle' => 'xXxX:xXXx'
                                                 })
      body = "invalidate_handle:xXxX:xXXx\nis_valid:true\n"

      webresponse = @encode.call(response)
      assert_equal(webresponse.code, Server::HTTP_OK)
      assert_equal(webresponse.headers, {})
      assert_equal(webresponse.body, body)
    end

    def test_unencodableError
      args = Message.from_post_args({
                                      'openid.identity' => 'http://limu.unittest/',
                                    })
      e = Server::ProtocolError.new(args, "wet paint")
      assert_raise(Server::EncodingError) {
        @encode.call(e)
      }
    end

    def test_encodableError
      args = Message.from_post_args({
                                      'openid.mode' => 'associate',
                                      'openid.identity' => 'http://limu.unittest/',
                                    })
      body="error:snoot\nmode:error\n"
      webresponse = @encode.call(Server::ProtocolError.new(args, "snoot"))
      assert_equal(webresponse.code, Server::HTTP_ERROR)
      assert_equal(webresponse.headers, {})
      assert_equal(webresponse.body, body)
    end
  end

  class TestSigningEncode < Test::Unit::TestCase
    def setup
      @_dumb_key = Server::Signatory._dumb_key
      @_normal_key = Server::Signatory._normal_key
      @store = Store::Memory.new()
      @server = Server::Server.new(@store, "http://signing.unittest/enc")
      @request = Server::CheckIDRequest.new(
                                    'http://bombom.unittest/',
                                    'http://burr.unittest/999',
                                    @server.op_endpoint,
                                    'http://burr.unittest/',
                                    false, nil)
      @request.message = Message.new(OPENID2_NS)

      @response = Server::OpenIDResponse.new(@request)
      @response.fields = Message.from_openid_args({
                                                    'mode' => 'id_res',
                                                    'identity' => @request.identity,
                                                    'return_to' => @request.return_to,
                                                  })
      @signatory = Server::Signatory.new(@store)
      @encoder = Server::SigningEncoder.new(@signatory)
      @encode = @encoder.method('encode')
    end

    def test_idres
      assoc_handle = '{bicycle}{shed}'
      @store.store_association(
                               @_normal_key,
                               Association.from_expires_in(60, assoc_handle,
                                                           'sekrit', 'HMAC-SHA1'))
      @request.assoc_handle = assoc_handle
      webresponse = @encode.call(@response)
      assert_equal(webresponse.code, Server::HTTP_REDIRECT)
      assert(webresponse.headers.member?('location'))

      location = webresponse.headers['location']
      query = Util.parse_query(URI::parse(location).query)
      assert(query.member?('openid.sig'))
      assert(query.member?('openid.assoc_handle'))
      assert(query.member?('openid.signed'))
    end

    def test_idresDumb
      webresponse = @encode.call(@response)
      assert_equal(webresponse.code, Server::HTTP_REDIRECT)
      assert(webresponse.headers.has_key?('location'))

      location = webresponse.headers['location']
      query = Util.parse_query(URI::parse(location).query)
      assert(query.member?('openid.sig'))
      assert(query.member?('openid.assoc_handle'))
      assert(query.member?('openid.signed'))
    end

    def test_forgotStore
      @encoder.signatory = nil
      assert_raise(ArgumentError) {
        @encode.call(@response)
      }
    end

    def test_cancel
      request = Server::CheckIDRequest.new(
                                   'http://bombom.unittest/',
                                   'http://burr.unittest/999',
                                   @server.op_endpoint,
                                   'http://burr.unittest/',
                                   false, nil)
      request.message = Message.new(OPENID2_NS)
      response = Server::OpenIDResponse.new(request)
      response.fields.set_arg(OPENID_NS, 'mode', 'cancel')
      webresponse = @encode.call(response)
      assert_equal(webresponse.code, Server::HTTP_REDIRECT)
      assert(webresponse.headers.has_key?('location'))
      location = webresponse.headers['location']
      query = Util.parse_query(URI::parse(location).query)
      assert(!query.has_key?('openid.sig'), response.fields.to_post_args())
    end

    def test_assocReply
      msg = Message.new(OPENID2_NS)
      msg.set_arg(OPENID2_NS, 'session_type', 'no-encryption')
      request = Server::AssociateRequest.from_message(msg)
      response = Server::OpenIDResponse.new(request)
      response.fields = Message.from_openid_args({'assoc_handle' => "every-zig"})
      webresponse = @encode.call(response)
      body = "assoc_handle:every-zig\n"
      assert_equal(webresponse.code, Server::HTTP_OK)
      assert_equal(webresponse.headers, {})
      assert_equal(webresponse.body, body)
    end

    def test_alreadySigned
      @response.fields.set_arg(OPENID_NS, 'sig', 'priorSig==')
      assert_raise(Server::AlreadySigned) {
        @encode.call(@response)
      }
    end
  end

  class TestCheckID < Test::Unit::TestCase
    def setup
      @op_endpoint = 'http://endpoint.unittest/'
      @store = Store::Memory.new()
      @server = Server::Server.new(@store, @op_endpoint)
      @request = Server::CheckIDRequest.new(
                                    'http://bambam.unittest/',
                                    'http://bar.unittest/999',
                                    @server.op_endpoint,
                                    'http://bar.unittest/',
                                    false)
      @request.message = Message.new(OPENID2_NS)
    end

    def test_trustRootInvalid
      @request.trust_root = "http://foo.unittest/17"
      @request.return_to = "http://foo.unittest/39"
      assert(!@request.trust_root_valid())
    end

    def test_trustRootInvalid_modified
      @request.trust_root = "does://not.parse/"
      @request.message = :sentinel
      begin
        result = @request.trust_root_valid
      rescue Server::MalformedTrustRoot => why
        assert_equal(:sentinel, why.openid_message)
      else
        flunk("Expected MalformedTrustRoot, got #{result.inspect}")
      end
    end

    def test_trustRootvalid_absent_trust_root
      @request.trust_root = nil
      assert(@request.trust_root_valid())
    end

    def test_trustRootValid
      @request.trust_root = "http://foo.unittest/"
      @request.return_to = "http://foo.unittest/39"
      assert(@request.trust_root_valid())
    end

    def test_trustRootValidNoReturnTo
      request = Server::CheckIDRequest.new(
                                   'http://bambam.unittest/',
                                   nil,
                                   @server.op_endpoint,
                                   'http://bar.unittest/',
                                   false)

      assert(request.trust_root_valid())
    end

    def test_returnToVerified_callsVerify
      # Make sure that verifyReturnTo is calling the trustroot
      # function verifyReturnTo
      # Ensure that exceptions are passed through
      sentinel = Exception.new()

      __req = @request
      tc = self

      vrfyExc = Proc.new { |trust_root, return_to|
        tc.assert_equal(__req.trust_root, trust_root)
        tc.assert_equal(__req.return_to, return_to)
        raise sentinel
      }

      TrustRoot.extend(OverrideMethodMixin)

      TrustRoot.with_method_overridden(:verify_return_to, vrfyExc) do
        begin
          @request.return_to_verified()
          flunk("Expected sentinel to be raised, got success")
        rescue Exception => e
          assert(e.equal?(sentinel), [e, sentinel].inspect)
        end
      end

      # Ensure that True and False are passed through unchanged
      constVerify = Proc.new { |val|
        verify = Proc.new { |trust_root, return_to|
          tc.assert_equal(__req.trust_root, trust_root)
          tc.assert_equal(__req.request.return_to, return_to)
          return val
        }

        return verify
      }

      [true, false].each { |val|
        verifier = constVerify.call(val)

        TrustRoot.with_method_overridden(:verify_return_to, verifier) do
          assert_equal(val, @request.return_to_verified())
        end
      }
    end

    def _expectAnswer(answer, identity=nil, claimed_id=nil)
      expected_list = [
                       ['mode', 'id_res'],
                       ['return_to', @request.return_to],
                       ['op_endpoint', @op_endpoint],
                      ]
      if identity
        expected_list << ['identity', identity]
        if claimed_id
          expected_list << ['claimed_id', claimed_id]
        else
          expected_list << ['claimed_id', identity]
        end
      end

      expected_list.each { |k, expected|
        actual = answer.fields.get_arg(OPENID_NS, k)
        assert_equal(expected, actual,
                     sprintf("%s: expected %s, got %s",
                             k, expected, actual))
      }

      assert(answer.fields.has_key?(OPENID_NS, 'response_nonce'))
      assert(answer.fields.get_openid_namespace() == OPENID2_NS)

      # One for nonce, one for ns
      assert_equal(answer.fields.to_post_args.length,
                   expected_list.length + 2,
                   answer.fields.to_post_args.inspect)
    end

    def test_answerAllow
      # Check the fields specified by "Positive Assertions"
      #
      # including mode=id_res, identity, claimed_id, op_endpoint,
      # return_to
      answer = @request.answer(true)
      assert_equal(answer.request, @request)
      _expectAnswer(answer, @request.identity)
    end

    def test_answerAllowDelegatedIdentity
      @request.claimed_id = 'http://delegating.unittest/'
      answer = @request.answer(true)
      _expectAnswer(answer, @request.identity,
                    @request.claimed_id)
    end

    def test_answerAllowWithoutIdentityReally
      @request.identity = nil
      answer = @request.answer(true)
      assert_equal(answer.request, @request)
      _expectAnswer(answer)
    end

    def test_answerAllowAnonymousFail
      @request.identity = nil
      # XXX - Check on this, I think this behavior is legal in OpenID
      # 2.0?
      assert_raise(ArgumentError) {
        @request.answer(true, nil, "=V")
      }
    end

    def test_answerAllowWithIdentity
      @request.identity = IDENTIFIER_SELECT
      selected_id = 'http://anon.unittest/9861'
      answer = @request.answer(true, nil, selected_id)
      _expectAnswer(answer, selected_id)
    end

    def test_answerAllowWithNoIdentity
      @request.identity = IDENTIFIER_SELECT
      selected_id = 'http://anon.unittest/9861'
      assert_raise(ArgumentError) {
        answer = @request.answer(true, nil, nil)
      }
    end

    def test_immediate_openid1_no_identity
      @request.message = Message.new(OPENID1_NS)
      @request.immediate = true
      @request.mode = 'checkid_immediate'
      resp = @request.answer(false)
      assert(resp.fields.get_arg(OPENID_NS, 'mode') == 'id_res')
    end

    def test_checkid_setup_openid1_no_identity
      @request.message = Message.new(OPENID1_NS)
      @request.immediate = false
      @request.mode = 'checkid_setup'
      resp = @request.answer(false)
      assert(resp.fields.get_arg(OPENID_NS, 'mode') == 'cancel')
    end

    def test_immediate_openid1_no_server_url
      @request.message = Message.new(OPENID1_NS)
      @request.immediate = true
      @request.mode = 'checkid_immediate'
      @request.op_endpoint = nil

      assert_raise(ArgumentError) {
        resp = @request.answer(false)
      }
    end

    def test_immediate_encode_to_url
      @request.message = Message.new(OPENID1_NS)
      @request.immediate = true
      @request.mode = 'checkid_immediate'
      @request.trust_root = "BOGUS"
      @request.assoc_handle = "ASSOC"

      server_url = "http://server.com/server"

      url = @request.encode_to_url(server_url)
      assert(url.starts_with?(server_url))

      unused, query = url.split("?", 2)
      args = Util.parse_query(query)

      m = Message.from_post_args(args)
      assert(m.get_arg(OPENID_NS, 'trust_root') == "BOGUS")
      assert(m.get_arg(OPENID_NS, 'assoc_handle') == "ASSOC")
      assert(m.get_arg(OPENID_NS, 'mode'), "checkid_immediate")
      assert(m.get_arg(OPENID_NS, 'identity') == @request.identity)
      assert(m.get_arg(OPENID_NS, 'claimed_id') == @request.claimed_id)
      assert(m.get_arg(OPENID_NS, 'return_to') == @request.return_to)
    end

    def test_answerAllowWithDelegatedIdentityOpenID2
      # Answer an IDENTIFIER_SELECT case with a delegated identifier.

      # claimed_id delegates to selected_id here.
      @request.identity = IDENTIFIER_SELECT
      selected_id = 'http://anon.unittest/9861'
      claimed_id = 'http://monkeyhat.unittest/'
      answer = @request.answer(true, nil, selected_id, claimed_id)
      _expectAnswer(answer, selected_id, claimed_id)
    end

    def test_answerAllowWithDelegatedIdentityOpenID1
      # claimed_id parameter doesn't exist in OpenID 1.
      @request.message = Message.new(OPENID1_NS)
      # claimed_id delegates to selected_id here.
      @request.identity = IDENTIFIER_SELECT
      selected_id = 'http://anon.unittest/9861'
      claimed_id = 'http://monkeyhat.unittest/'
      assert_raise(Server::VersionError) {
        @request.answer(true, nil, selected_id, claimed_id)
      }
    end

    def test_answerAllowWithAnotherIdentity
      # XXX - Check on this, I think this behavior is legal in OpenID
      # 2.0?
      assert_raise(ArgumentError){
        @request.answer(true, nil, "http://pebbles.unittest/")
      }
    end

    def test_answerAllowNoIdentityOpenID1
      @request.message = Message.new(OPENID1_NS)
      @request.identity = nil
      assert_raise(ArgumentError) {
        @request.answer(true, nil, nil)
      }
    end

    def test_answerAllowForgotEndpoint
      @request.op_endpoint = nil
      assert_raise(RuntimeError) {
        @request.answer(true)
      }
    end

    def test_checkIDWithNoIdentityOpenID1
      msg = Message.new(OPENID1_NS)
      msg.set_arg(OPENID_NS, 'return_to', 'bogus')
      msg.set_arg(OPENID_NS, 'trust_root', 'bogus')
      msg.set_arg(OPENID_NS, 'mode', 'checkid_setup')
      msg.set_arg(OPENID_NS, 'assoc_handle', 'bogus')

      assert_raise(Server::ProtocolError) {
        Server::CheckIDRequest.from_message(msg, @server)
      }
    end

    def test_fromMessageClaimedIDWithoutIdentityOpenID2
      msg = Message.new(OPENID2_NS)
      msg.set_arg(OPENID_NS, 'mode', 'checkid_setup')
      msg.set_arg(OPENID_NS, 'return_to', 'http://invalid:8000/rt')
      msg.set_arg(OPENID_NS, 'claimed_id', 'https://example.myopenid.com')

      assert_raise(Server::ProtocolError) {
        Server::CheckIDRequest.from_message(msg, @server)
      }
    end

    def test_fromMessageIdentityWithoutClaimedIDOpenID2
      msg = Message.new(OPENID2_NS)
      msg.set_arg(OPENID_NS, 'mode', 'checkid_setup')
      msg.set_arg(OPENID_NS, 'return_to', 'http://invalid:8000/rt')
      msg.set_arg(OPENID_NS, 'identity', 'https://example.myopenid.com')

      assert_raise(Server::ProtocolError) {
        Server::CheckIDRequest.from_message(msg, @server)
      }
    end

    def test_fromMessageWithEmptyTrustRoot
      return_to = 'http://some.url/foo?bar=baz'
      msg = Message.from_post_args({
              'openid.assoc_handle' => '{blah}{blah}{OZivdQ==}',
              'openid.claimed_id' => 'http://delegated.invalid/',
              'openid.identity' => 'http://op-local.example.com/',
              'openid.mode' => 'checkid_setup',
              'openid.ns' => 'http://openid.net/signon/1.0',
              'openid.return_to' => return_to,
              'openid.trust_root' => ''
              });
      result = Server::CheckIDRequest.from_message(msg, @server)
      assert_equal(return_to, result.trust_root)
    end

    def test_trustRootOpenID1
      # Ignore openid.realm in OpenID 1
      msg = Message.new(OPENID1_NS)
      msg.set_arg(OPENID_NS, 'mode', 'checkid_setup')
      msg.set_arg(OPENID_NS, 'trust_root', 'http://trustroot.com/')
      msg.set_arg(OPENID_NS, 'realm', 'http://fake_trust_root/')
      msg.set_arg(OPENID_NS, 'return_to', 'http://trustroot.com/foo')
      msg.set_arg(OPENID_NS, 'assoc_handle', 'bogus')
      msg.set_arg(OPENID_NS, 'identity', 'george')

      result = Server::CheckIDRequest.from_message(msg, @server.op_endpoint)

      assert(result.trust_root == 'http://trustroot.com/')
    end

    def test_trustRootOpenID2
      # Ignore openid.trust_root in OpenID 2
      msg = Message.new(OPENID2_NS)
      msg.set_arg(OPENID_NS, 'mode', 'checkid_setup')
      msg.set_arg(OPENID_NS, 'realm', 'http://trustroot.com/')
      msg.set_arg(OPENID_NS, 'trust_root', 'http://fake_trust_root/')
      msg.set_arg(OPENID_NS, 'return_to', 'http://trustroot.com/foo')
      msg.set_arg(OPENID_NS, 'assoc_handle', 'bogus')
      msg.set_arg(OPENID_NS, 'identity', 'george')
      msg.set_arg(OPENID_NS, 'claimed_id', 'george')

      result = Server::CheckIDRequest.from_message(msg, @server.op_endpoint)

      assert(result.trust_root == 'http://trustroot.com/')
    end

    def test_answerAllowNoTrustRoot
      @request.trust_root = nil
      answer = @request.answer(true)
      assert_equal(answer.request, @request)
      _expectAnswer(answer, @request.identity)
    end

    def test_answerImmediateDenyOpenID2
      # Look for mode=setup_needed in checkid_immediate negative
      # response in OpenID 2 case.
      #
      # See specification Responding to Authentication Requests /
      # Negative Assertions / In Response to Immediate Requests.
      @request.mode = 'checkid_immediate'
      @request.immediate = true

      server_url = "http://setup-url.unittest/"
      # crappiting setup_url, you dirty my interface with your presence!
      answer = @request.answer(false, server_url)
      assert_equal(answer.request, @request)
      assert_equal(answer.fields.to_post_args.length, 3, answer.fields)
      assert_equal(answer.fields.get_openid_namespace, OPENID2_NS)
      assert_equal(answer.fields.get_arg(OPENID_NS, 'mode'),
                   'setup_needed')
      # user_setup_url no longer required.
    end

    def test_answerImmediateDenyOpenID1
      # Look for user_setup_url in checkid_immediate negative response
      # in OpenID 1 case.
      @request.message = Message.new(OPENID1_NS)
      @request.mode = 'checkid_immediate'
      @request.immediate = true
      @request.claimed_id = 'http://claimed-id.test/'
      server_url = "http://setup-url.unittest/"
      # crappiting setup_url, you dirty my interface with your presence!
      answer = @request.answer(false, server_url)
      assert_equal(answer.request, @request)
      assert_equal(2, answer.fields.to_post_args.length, answer.fields)
      assert_equal(OPENID1_NS, answer.fields.get_openid_namespace)
      assert_equal('id_res', answer.fields.get_arg(OPENID_NS, 'mode'))

      usu = answer.fields.get_arg(OPENID_NS, 'user_setup_url', '')
      assert(usu.starts_with?(server_url))
      expected_substr = 'openid.claimed_id=http%3A%2F%2Fclaimed-id.test%2F'
      assert(!usu.index(expected_substr).nil?, usu)
    end

    def test_answerSetupDeny
      answer = @request.answer(false)
      assert_equal(answer.fields.get_args(OPENID_NS), {
                     'mode' => 'cancel',
                   })
    end

    def test_encodeToURL
      server_url = 'http://openid-server.unittest/'
      result = @request.encode_to_url(server_url)

      # How to check?  How about a round-trip test.
      base, result_args = result.split('?', 2)
      result_args = Util.parse_query(result_args)
      message = Message.from_post_args(result_args)
      rebuilt_request = Server::CheckIDRequest.from_message(message,
                                                    @server.op_endpoint)

      @request.message = message

      @request.instance_variables.each { |var|
        assert_equal(@request.instance_variable_get(var),
                     rebuilt_request.instance_variable_get(var), var)
      }
    end

    def test_getCancelURL
      url = @request.cancel_url
      rt, query_string = url.split('?', -1)
      assert_equal(@request.return_to, rt)
      query = Util.parse_query(query_string)
      assert_equal(query, {'openid.mode' => 'cancel',
                     'openid.ns' => OPENID2_NS})
    end

    def test_getCancelURLimmed
      @request.mode = 'checkid_immediate'
      @request.immediate = true
      assert_raise(ArgumentError) {
        @request.cancel_url
      }
    end

    def test_fromMessageWithoutTrustRoot
        msg = Message.new(OPENID2_NS)
        msg.set_arg(OPENID_NS, 'mode', 'checkid_setup')
        msg.set_arg(OPENID_NS, 'return_to', 'http://real.trust.root/foo')
        msg.set_arg(OPENID_NS, 'assoc_handle', 'bogus')
        msg.set_arg(OPENID_NS, 'identity', 'george')
        msg.set_arg(OPENID_NS, 'claimed_id', 'george')

        result = Server::CheckIDRequest.from_message(msg, @server.op_endpoint)

        assert_equal(result.trust_root, 'http://real.trust.root/foo')
    end

    def test_fromMessageWithoutTrustRootOrReturnTo
        msg = Message.new(OPENID2_NS)
        msg.set_arg(OPENID_NS, 'mode', 'checkid_setup')
        msg.set_arg(OPENID_NS, 'assoc_handle', 'bogus')
        msg.set_arg(OPENID_NS, 'identity', 'george')
        msg.set_arg(OPENID_NS, 'claimed_id', 'george')

        assert_raises(Server::ProtocolError) {
          Server::CheckIDRequest.from_message(msg, @server.op_endpoint)
        }
    end
  end

  class TestCheckIDExtension < Test::Unit::TestCase

    def setup
      @op_endpoint = 'http://endpoint.unittest/ext'
      @store = Store::Memory.new()
      @server = Server::Server.new(@store, @op_endpoint)
      @request = Server::CheckIDRequest.new(
                                    'http://bambam.unittest/',
                                    'http://bar.unittest/999',
                                    @server.op_endpoint,
                                    'http://bar.unittest/',
                                    false)
      @request.message = Message.new(OPENID2_NS)
      @response = Server::OpenIDResponse.new(@request)
      @response.fields.set_arg(OPENID_NS, 'mode', 'id_res')
      @response.fields.set_arg(OPENID_NS, 'blue', 'star')
    end

    def test_addField
      namespace = 'something:'
      @response.fields.set_arg(namespace, 'bright', 'potato')
      assert_equal(@response.fields.get_args(OPENID_NS),
                   {'blue' => 'star',
                     'mode' => 'id_res',
                   })
      
      assert_equal(@response.fields.get_args(namespace),
                   {'bright' => 'potato'})
    end

    def test_addFields
      namespace = 'mi5:'
      args =  {'tangy' => 'suspenders',
        'bravo' => 'inclusion'}
      @response.fields.update_args(namespace, args)
      assert_equal(@response.fields.get_args(OPENID_NS),
                   {'blue' => 'star',
                     'mode' => 'id_res',
                   })
      assert_equal(@response.fields.get_args(namespace), args)
    end
  end

  class MockSignatory
    attr_accessor :isValid, :assocs

    def initialize(assoc)
      @isValid = true
      @assocs = [assoc]
    end

    def verify(assoc_handle, message)
      Util.assert(message.has_key?(OPENID_NS, "sig"))
      if self.assocs.member?([true, assoc_handle])
        return @isValid
      else
        return false
      end
    end

    def get_association(assoc_handle, dumb)
      if self.assocs.member?([dumb, assoc_handle])
        # This isn't a valid implementation for many uses of this
        # function, mind you.
        return true
      else
        return nil
      end
    end

    def invalidate(assoc_handle, dumb)
      if self.assocs.member?([dumb, assoc_handle])
        @assocs.delete([dumb, assoc_handle])
      end
    end
  end

  class TestCheckAuth < Test::Unit::TestCase
    def setup
      @assoc_handle = 'mooooooooo'
      @message = Message.from_post_args({
                                          'openid.sig' => 'signarture',
                                          'one' => 'alpha',
                                          'two' => 'beta',
                                        })
      @request = Server::CheckAuthRequest.new(
                                      @assoc_handle, @message)
      @request.message = Message.new(OPENID2_NS)

      @signatory = MockSignatory.new([true, @assoc_handle])
    end

    def test_to_s
      @request.to_s
    end

    def test_valid
      r = @request.answer(@signatory)
      assert_equal({'is_valid' => 'true'},
                   r.fields.get_args(OPENID_NS))
      assert_equal(r.request, @request)
    end

    def test_invalid
      @signatory.isValid = false
      r = @request.answer(@signatory)
      assert_equal({'is_valid' => 'false'},
                   r.fields.get_args(OPENID_NS))
      
    end

    def test_replay
      # Don't validate the same response twice.
      #
      # From "Checking the Nonce"::
      #
      #   When using "check_authentication", the OP MUST ensure that an
      #   assertion has not yet been accepted with the same value for
      #   "openid.response_nonce".
      #
      # In this implementation, the assoc_handle is only valid once.
      # And nonces are a signed component of the message, so they can't
      # be used with another handle without breaking the sig.
      r = @request.answer(@signatory)
      r = @request.answer(@signatory)
      assert_equal({'is_valid' => 'false'},
                   r.fields.get_args(OPENID_NS))
    end

    def test_invalidatehandle
      @request.invalidate_handle = "bogusHandle"
      r = @request.answer(@signatory)
      assert_equal(r.fields.get_args(OPENID_NS),
                   {'is_valid' => 'true',
                     'invalidate_handle' => "bogusHandle"})
      assert_equal(r.request, @request)
    end

    def test_invalidatehandleNo
      assoc_handle = 'goodhandle'
      @signatory.assocs << [false, 'goodhandle']
      @request.invalidate_handle = assoc_handle
      r = @request.answer(@signatory)
      assert_equal(r.fields.get_args(OPENID_NS), {'is_valid' => 'true'})
    end
  end

  class TestAssociate < Test::Unit::TestCase
    # TODO: test DH with non-default values for modulus and gen.
    # (important to do because we actually had it broken for a while.)

    def setup
      @request = Server::AssociateRequest.from_message(Message.from_post_args({}))
      @store = Store::Memory.new()
      @signatory = Server::Signatory.new(@store)
    end

    def test_dhSHA1
      @assoc = @signatory.create_association(false, 'HMAC-SHA1')
      consumer_dh = DiffieHellman.from_defaults()
      cpub = consumer_dh.public
      server_dh = DiffieHellman.from_defaults()
      session = Server::DiffieHellmanSHA1ServerSession.new(server_dh, cpub)
      @request = Server::AssociateRequest.new(session, 'HMAC-SHA1')
      @request.message = Message.new(OPENID2_NS)
      response = @request.answer(@assoc)
      rfg = lambda { |f| response.fields.get_arg(OPENID_NS, f) }
      assert_equal(rfg.call("assoc_type"), "HMAC-SHA1")
      assert_equal(rfg.call("assoc_handle"), @assoc.handle)
      assert(!rfg.call("mac_key"))
      assert_equal(rfg.call("session_type"), "DH-SHA1")
      assert(rfg.call("enc_mac_key"))
      assert(rfg.call("dh_server_public"))

      enc_key = Util.from_base64(rfg.call("enc_mac_key"))
      spub = CryptUtil.base64_to_num(rfg.call("dh_server_public"))
      secret = consumer_dh.xor_secret(CryptUtil.method('sha1'),
                                      spub, enc_key)
      assert_equal(secret, @assoc.secret)
    end

    def test_dhSHA256
      @assoc = @signatory.create_association(false, 'HMAC-SHA256')
      consumer_dh = DiffieHellman.from_defaults()
      cpub = consumer_dh.public
      server_dh = DiffieHellman.from_defaults()
      session = Server::DiffieHellmanSHA256ServerSession.new(server_dh, cpub)
      @request = Server::AssociateRequest.new(session, 'HMAC-SHA256')
      @request.message = Message.new(OPENID2_NS)
      response = @request.answer(@assoc)
      rfg = lambda { |f| response.fields.get_arg(OPENID_NS, f) }
      assert_equal(rfg.call("assoc_type"), "HMAC-SHA256")
      assert_equal(rfg.call("assoc_handle"), @assoc.handle)
      assert(!rfg.call("mac_key"))
      assert_equal(rfg.call("session_type"), "DH-SHA256")
      assert(rfg.call("enc_mac_key"))
      assert(rfg.call("dh_server_public"))

      enc_key = Util.from_base64(rfg.call("enc_mac_key"))
      spub = CryptUtil.base64_to_num(rfg.call("dh_server_public"))
      secret = consumer_dh.xor_secret(CryptUtil.method('sha256'),
                                      spub, enc_key)
      assert_equal(secret, @assoc.secret)
    end

    def test_protoError256
      s256_session = Consumer::DiffieHellmanSHA256Session.new()

      invalid_s256 = {'openid.assoc_type' => 'HMAC-SHA1',
        'openid.session_type' => 'DH-SHA256',}
      invalid_s256.merge!(s256_session.get_request())

      invalid_s256_2 = {'openid.assoc_type' => 'MONKEY-PIRATE',
        'openid.session_type' => 'DH-SHA256',}
      invalid_s256_2.merge!(s256_session.get_request())

      bad_request_argss = [
                           invalid_s256,
                           invalid_s256_2,
                          ]

      bad_request_argss.each { |request_args|
        message = Message.from_post_args(request_args)
        assert_raise(Server::ProtocolError) {
          Server::AssociateRequest.from_message(message)
        }
      }
    end

    def test_protoError
      s1_session = Consumer::DiffieHellmanSHA1Session.new()

      invalid_s1 = {'openid.assoc_type' => 'HMAC-SHA256',
        'openid.session_type' => 'DH-SHA1',}
      invalid_s1.merge!(s1_session.get_request())

      invalid_s1_2 = {'openid.assoc_type' => 'ROBOT-NINJA',
        'openid.session_type' => 'DH-SHA1',}
      invalid_s1_2.merge!(s1_session.get_request())

      bad_request_argss = [
                           {'openid.assoc_type' => 'Wha?'},
                           invalid_s1,
                           invalid_s1_2,
                          ]
            
      bad_request_argss.each { |request_args|
        message = Message.from_post_args(request_args)
        assert_raise(Server::ProtocolError) {
          Server::AssociateRequest.from_message(message)
        }
      }
    end

    def test_protoErrorFields

      contact = 'user@example.invalid'
      reference = 'Trac ticket number MAX_INT'
      error = 'poltergeist'

      openid1_args = {
        'openid.identitiy' => 'invalid',
        'openid.mode' => 'checkid_setup',
      }

      openid2_args = openid1_args.dup
      openid2_args.merge!({'openid.ns' => OPENID2_NS})

      # Check presence of optional fields in both protocol versions

      openid1_msg = Message.from_post_args(openid1_args)
      p = Server::ProtocolError.new(openid1_msg, error,
                                    reference, contact)
      reply = p.to_message()

      assert_equal(reply.get_arg(OPENID_NS, 'reference'), reference)
      assert_equal(reply.get_arg(OPENID_NS, 'contact'), contact)

      openid2_msg = Message.from_post_args(openid2_args)
      p = Server::ProtocolError.new(openid2_msg, error,
                                    reference, contact)
      reply = p.to_message()

      assert_equal(reply.get_arg(OPENID_NS, 'reference'), reference)
      assert_equal(reply.get_arg(OPENID_NS, 'contact'), contact)
    end

    def failUnlessExpiresInMatches(msg, expected_expires_in)
      expires_in_str = msg.get_arg(OPENID_NS, 'expires_in', NO_DEFAULT)
      expires_in = expires_in_str.to_i

      # Slop is necessary because the tests can sometimes get run
      # right on a second boundary
      slop = 1 # second
      difference = expected_expires_in - expires_in

      error_message = sprintf('"expires_in" value not within %s of expected: ' +
                              'expected=%s, actual=%s', slop, expected_expires_in,
                              expires_in)
      assert((0 <= difference and difference <= slop), error_message)
    end

    def test_plaintext
      @assoc = @signatory.create_association(false, 'HMAC-SHA1')
      response = @request.answer(@assoc)
      rfg = lambda { |f| response.fields.get_arg(OPENID_NS, f) }

      assert_equal(rfg.call("assoc_type"), "HMAC-SHA1")
      assert_equal(rfg.call("assoc_handle"), @assoc.handle)

      failUnlessExpiresInMatches(response.fields,
                                 @signatory.secret_lifetime)

      assert_equal(
                   rfg.call("mac_key"), Util.to_base64(@assoc.secret))
      assert(!rfg.call("session_type"))
      assert(!rfg.call("enc_mac_key"))
      assert(!rfg.call("dh_server_public"))
    end

    def test_plaintext_v2
        # The main difference between this and the v1 test is that
        # session_type is always returned in v2.
        args = {
            'openid.ns' => OPENID2_NS,
            'openid.mode' => 'associate',
            'openid.assoc_type' => 'HMAC-SHA1',
            'openid.session_type' => 'no-encryption',
            }
        @request = Server::AssociateRequest.from_message(
          Message.from_post_args(args))

        assert(!@request.message.is_openid1())

        @assoc = @signatory.create_association(false, 'HMAC-SHA1')
        response = @request.answer(@assoc)
        rfg = lambda { |f| response.fields.get_arg(OPENID_NS, f) }

        assert_equal(rfg.call("assoc_type"), "HMAC-SHA1")
        assert_equal(rfg.call("assoc_handle"), @assoc.handle)

        failUnlessExpiresInMatches(
            response.fields, @signatory.secret_lifetime)

        assert_equal(
            rfg.call("mac_key"), Util.to_base64(@assoc.secret))

        assert_equal(rfg.call("session_type"), "no-encryption")
        assert(!rfg.call("enc_mac_key"))
        assert(!rfg.call("dh_server_public"))
    end

    def test_plaintext256
      @assoc = @signatory.create_association(false, 'HMAC-SHA256')
      response = @request.answer(@assoc)
      rfg = lambda { |f| response.fields.get_arg(OPENID_NS, f) }

      assert_equal(rfg.call("assoc_type"), "HMAC-SHA1")
      assert_equal(rfg.call("assoc_handle"), @assoc.handle)

      failUnlessExpiresInMatches(
                                 response.fields, @signatory.secret_lifetime)

      assert_equal(
                   rfg.call("mac_key"), Util.to_base64(@assoc.secret))
      assert(!rfg.call("session_type"))
      assert(!rfg.call("enc_mac_key"))
      assert(!rfg.call("dh_server_public"))
    end

    def test_unsupportedPrefer
      allowed_assoc = 'COLD-PET-RAT'
      allowed_sess = 'FROG-BONES'
      message = 'This is a unit test'

      # Set an OpenID 2 message so answerUnsupported doesn't raise
      # ProtocolError.
      @request.message = Message.new(OPENID2_NS)

      response = @request.answer_unsupported(message,
                                             allowed_assoc,
                                             allowed_sess)
      rfg = lambda { |f| response.fields.get_arg(OPENID_NS, f) }
      assert_equal(rfg.call('error_code'), 'unsupported-type')
      assert_equal(rfg.call('assoc_type'), allowed_assoc)
      assert_equal(rfg.call('error'), message)
      assert_equal(rfg.call('session_type'), allowed_sess)
    end

    def test_unsupported
      message = 'This is a unit test'

      # Set an OpenID 2 message so answerUnsupported doesn't raise
      # ProtocolError.
      @request.message = Message.new(OPENID2_NS)

      response = @request.answer_unsupported(message)
      rfg = lambda { |f| response.fields.get_arg(OPENID_NS, f) }
      assert_equal(rfg.call('error_code'), 'unsupported-type')
      assert_equal(rfg.call('assoc_type'), nil)
      assert_equal(rfg.call('error'), message)
      assert_equal(rfg.call('session_type'), nil)
    end

    def test_openid1_unsupported_explode
      # answer_unsupported on an associate request should explode if
      # the request was an OpenID 1 request.
      m = Message.new(OPENID1_NS)

      assert_raise(Server::ProtocolError) {
        @request.answer_unsupported(m)
      }
    end
  end

  class Counter
    def initialize
      @count = 0
    end

    def inc
      @count += 1
    end
  end

  class UnhandledError < Exception
  end

  class TestServer < Test::Unit::TestCase
    include TestUtil

    def setup
      @store = Store::Memory.new()
      @server = Server::Server.new(@store, "http://server.unittest/endpt")
      # catchlogs_setup()
    end

    def test_failed_dispatch
      request = Server::OpenIDRequest.new()
      request.mode = "monkeymode"
      request.message = Message.new(OPENID1_NS)
      assert_raise(RuntimeError) {
        webresult = @server.handle_request(request)
      }
    end

    def test_decode_request
      @server.decoder = BogusDecoder.new(@server)
      assert(@server.decode_request({}) == "BOGUS")
    end

    def test_encode_response
      @server.encoder = BogusEncoder.new
      assert(@server.encode_response(nil) == "BOGUS")
    end

    def test_dispatch
      monkeycalled = Counter.new()

      @server.extend(InstanceDefExtension)
      @server.instance_def(:openid_monkeymode) do |request|
        raise UnhandledError
      end

      request = Server::OpenIDRequest.new()
      request.mode = "monkeymode"
      request.message = Message.new(OPENID1_NS)
      assert_raise(UnhandledError) {
        webresult = @server.handle_request(request)
      }
    end

    def test_associate
      request = Server::AssociateRequest.from_message(Message.from_post_args({}))
      response = @server.openid_associate(request)
      assert(response.fields.has_key?(OPENID_NS, "assoc_handle"),
             sprintf("No assoc_handle here: %s", response.fields.inspect))
    end

    def test_associate2
      # Associate when the server has no allowed association types
      #
      # Gives back an error with error_code and no fallback session or
      # assoc types.
      @server.negotiator.allowed_types = []

      # Set an OpenID 2 message so answerUnsupported doesn't raise
      # ProtocolError.
      msg = Message.from_post_args({
                                     'openid.ns' => OPENID2_NS,
                                     'openid.session_type' => 'no-encryption',
                                   })

      request = Server::AssociateRequest.from_message(msg)

      response = @server.openid_associate(request)
      assert(response.fields.has_key?(OPENID_NS, "error"))
      assert(response.fields.has_key?(OPENID_NS, "error_code"))
      assert(!response.fields.has_key?(OPENID_NS, "assoc_handle"))
      assert(!response.fields.has_key?(OPENID_NS, "assoc_type"))
      assert(!response.fields.has_key?(OPENID_NS, "session_type"))
    end

    def test_associate3
      # Request an assoc type that is not supported when there are
      # supported types.
      #
      # Should give back an error message with a fallback type.
      @server.negotiator.allowed_types = [['HMAC-SHA256', 'DH-SHA256']]

      msg = Message.from_post_args({
                                     'openid.ns' => OPENID2_NS,
                                     'openid.session_type' => 'no-encryption',
                                   })

      request = Server::AssociateRequest.from_message(msg)
      response = @server.openid_associate(request)

      assert(response.fields.has_key?(OPENID_NS, "error"))
      assert(response.fields.has_key?(OPENID_NS, "error_code"))
      assert(!response.fields.has_key?(OPENID_NS, "assoc_handle"))

      assert_equal(response.fields.get_arg(OPENID_NS, "assoc_type"),
                   'HMAC-SHA256')
      assert_equal(response.fields.get_arg(OPENID_NS, "session_type"),
                   'DH-SHA256')
    end

    def test_associate4
      # DH-SHA256 association session
      @server.negotiator.allowed_types = [['HMAC-SHA256', 'DH-SHA256']]

      query = {
        'openid.dh_consumer_public' =>
        'ALZgnx8N5Lgd7pCj8K86T/DDMFjJXSss1SKoLmxE72kJTzOtG6I2PaYrHX' +
        'xku4jMQWSsGfLJxwCZ6280uYjUST/9NWmuAfcrBfmDHIBc3H8xh6RBnlXJ' +
        '1WxJY3jHd5k1/ZReyRZOxZTKdF/dnIqwF8ZXUwI6peV0TyS/K1fOfF/s',

        'openid.assoc_type' => 'HMAC-SHA256',
        'openid.session_type' => 'DH-SHA256',
      }

      message = Message.from_post_args(query)
      request = Server::AssociateRequest.from_message(message)
      response = @server.openid_associate(request)
      assert(response.fields.has_key?(OPENID_NS, "assoc_handle"))
    end

    def test_no_encryption_openid1
      # Make sure no-encryption associate requests for OpenID 1 are
      # logged.
      assert_log_matches(/Continuing anyway./) {
        m = Message.from_openid_args({
                                       'session_type' => 'no-encryption',
                                     })

        req = Server::AssociateRequest.from_message(m)
      }
    end

    def test_missingSessionTypeOpenID2
      # Make sure session_type is required in OpenID 2
      msg = Message.from_post_args({
                                     'openid.ns' => OPENID2_NS,
                                   })

      assert_raises(Server::ProtocolError) {
        Server::AssociateRequest.from_message(msg)
      }
    end

    def test_checkAuth
      request = Server::CheckAuthRequest.new('arrrrrf', '0x3999', [])
      request.message = Message.new(OPENID2_NS)
      response = nil
      silence_logging {
        response = @server.openid_check_authentication(request)
      }
      assert(response.fields.has_key?(OPENID_NS, "is_valid"))
    end
  end

  class TestingRequest < Server::OpenIDRequest
    attr_accessor :assoc_handle, :namespace
  end

  class TestSignatory < Test::Unit::TestCase
    include TestUtil

    def setup
      @store = Store::Memory.new()
      @signatory = Server::Signatory.new(@store)
      @_dumb_key = @signatory.class._dumb_key
      @_normal_key = @signatory.class._normal_key
      # CatchLogs.setUp(self)
    end

    def test_get_association_nil
      assert_raises(ArgumentError) {
        @signatory.get_association(nil, false)
      }
    end

    def test_sign
      request = TestingRequest.new()
      assoc_handle = '{assoc}{lookatme}'
      @store.store_association(
                               @_normal_key,
                               Association.from_expires_in(60, assoc_handle,
                                                           'sekrit', 'HMAC-SHA1'))
      request.assoc_handle = assoc_handle
      request.namespace = OPENID1_NS
      response = Server::OpenIDResponse.new(request)
      response.fields = Message.from_openid_args({
                                                   'foo' => 'amsigned',
                                                   'bar' => 'notsigned',
                                                   'azu' => 'alsosigned',
                                                 })
      sresponse = @signatory.sign(response)
      assert_equal(
            sresponse.fields.get_arg(OPENID_NS, 'assoc_handle'),
            assoc_handle)
      assert_equal(sresponse.fields.get_arg(OPENID_NS, 'signed'),
                   'assoc_handle,azu,bar,foo,signed')
      assert(sresponse.fields.get_arg(OPENID_NS, 'sig'))
      # assert(!@messages, @messages)
    end

    def test_signDumb
      request = TestingRequest.new()
      request.assoc_handle = nil
      request.namespace = OPENID2_NS
      response = Server::OpenIDResponse.new(request)
      response.fields = Message.from_openid_args({
                                                   'foo' => 'amsigned',
                                                   'bar' => 'notsigned',
                                                   'azu' => 'alsosigned',
                                                   'ns' => OPENID2_NS,
                                                 })
      sresponse = @signatory.sign(response)
      assoc_handle = sresponse.fields.get_arg(OPENID_NS, 'assoc_handle')
      assert(assoc_handle)
      assoc = @signatory.get_association(assoc_handle, true)
      assert(assoc)
      assert_equal(sresponse.fields.get_arg(OPENID_NS, 'signed'),
                   'assoc_handle,azu,bar,foo,ns,signed')
      assert(sresponse.fields.get_arg(OPENID_NS, 'sig'))
      # assert(!@messages, @messages)
    end

    def test_signExpired
      # Sign a response to a message with an expired handle (using
      # invalidate_handle).
      #
      # From "Verifying with an Association":
      #
      #   If an authentication request included an association handle
      #   for an association between the OP and the Relying party, and
      #   the OP no longer wishes to use that handle (because it has
      #   expired or the secret has been compromised, for instance),
      #   the OP will send a response that must be verified directly
      #   with the OP, as specified in Section 11.3.2. In that
      #   instance, the OP will include the field
      #   "openid.invalidate_handle" set to the association handle
      #   that the Relying Party included with the original request.
      request = TestingRequest.new()
      request.namespace = OPENID2_NS
      assoc_handle = '{assoc}{lookatme}'
      @store.store_association(
                               @_normal_key,
                               Association.from_expires_in(-10, assoc_handle,
                                                           'sekrit', 'HMAC-SHA1'))
      assert(@store.get_association(@_normal_key, assoc_handle))

      request.assoc_handle = assoc_handle
      response = Server::OpenIDResponse.new(request)
      response.fields = Message.from_openid_args({
                                                   'foo' => 'amsigned',
                                                   'bar' => 'notsigned',
                                                   'azu' => 'alsosigned',
                                                 })
      sresponse = nil
      silence_logging {
        sresponse = @signatory.sign(response)
      }

      new_assoc_handle = sresponse.fields.get_arg(OPENID_NS, 'assoc_handle')
      assert(new_assoc_handle)
      assert(new_assoc_handle != assoc_handle)

      assert_equal(
            sresponse.fields.get_arg(OPENID_NS, 'invalidate_handle'),
            assoc_handle)

      assert_equal(sresponse.fields.get_arg(OPENID_NS, 'signed'),
                   'assoc_handle,azu,bar,foo,invalidate_handle,signed')
      assert(sresponse.fields.get_arg(OPENID_NS, 'sig'))

      # make sure the expired association is gone
      assert(!@store.get_association(@_normal_key, assoc_handle),
             "expired association is still retrievable.")

      # make sure the new key is a dumb mode association
      assert(@store.get_association(@_dumb_key, new_assoc_handle))
      assert(!@store.get_association(@_normal_key, new_assoc_handle))
      # assert(@messages)
    end

    def test_signInvalidHandle
      request = TestingRequest.new()
      request.namespace = OPENID2_NS
      assoc_handle = '{bogus-assoc}{notvalid}'

      request.assoc_handle = assoc_handle
      response = Server::OpenIDResponse.new(request)
      response.fields = Message.from_openid_args({
                                                   'foo' => 'amsigned',
                                                   'bar' => 'notsigned',
                                                   'azu' => 'alsosigned',
                                                 })
      sresponse = @signatory.sign(response)

      new_assoc_handle = sresponse.fields.get_arg(OPENID_NS, 'assoc_handle')
      assert(new_assoc_handle)
      assert(new_assoc_handle != assoc_handle)

      assert_equal(
            sresponse.fields.get_arg(OPENID_NS, 'invalidate_handle'),
            assoc_handle)

      assert_equal(
            sresponse.fields.get_arg(OPENID_NS, 'signed'),
                   'assoc_handle,azu,bar,foo,invalidate_handle,signed')
      assert(sresponse.fields.get_arg(OPENID_NS, 'sig'))

      # make sure the new key is a dumb mode association
      assert(@store.get_association(@_dumb_key, new_assoc_handle))
      assert(!@store.get_association(@_normal_key, new_assoc_handle))
      # @failIf(@messages, @messages)
    end

    def test_verify
      assoc_handle = '{vroom}{zoom}'
      assoc = Association.from_expires_in(
            60, assoc_handle, 'sekrit', 'HMAC-SHA1')

      @store.store_association(@_dumb_key, assoc)

      signed = Message.from_post_args({
                                        'openid.foo' => 'bar',
                                        'openid.apple' => 'orange',
                                        'openid.assoc_handle' => assoc_handle,
                                        'openid.signed' => 'apple,assoc_handle,foo,signed',
                                        'openid.sig' => 'uXoT1qm62/BB09Xbj98TQ8mlBco=',
                                      })

      verified = @signatory.verify(assoc_handle, signed)
      assert(verified)
      # assert(!@messages, @messages)
    end

    def test_verifyBadSig
      assoc_handle = '{vroom}{zoom}'
      assoc = Association.from_expires_in(
            60, assoc_handle, 'sekrit', 'HMAC-SHA1')

      @store.store_association(@_dumb_key, assoc)

      signed = Message.from_post_args({
            'openid.foo' => 'bar',
            'openid.apple' => 'orange',
            'openid.assoc_handle' => assoc_handle,
            'openid.signed' => 'apple,assoc_handle,foo,signed',
            'openid.sig' => 'uXoT1qm62/BB09Xbj98TQ8mlBco=BOGUS'
            })

      verified = @signatory.verify(assoc_handle, signed)
      # @failIf(@messages, @messages)
      assert(!verified)
    end

    def test_verifyBadHandle
      assoc_handle = '{vroom}{zoom}'
      signed = Message.from_post_args({
            'foo' => 'bar',
            'apple' => 'orange',
            'openid.sig' => "Ylu0KcIR7PvNegB/K41KpnRgJl0=",
            })

      verified = nil
      silence_logging {
        verified = @signatory.verify(assoc_handle, signed)
      }

      assert(!verified)
      #assert(@messages)
    end

    def test_verifyAssocMismatch
      # Attempt to validate sign-all message with a signed-list assoc.
      assoc_handle = '{vroom}{zoom}'
      assoc = Association.from_expires_in(
            60, assoc_handle, 'sekrit', 'HMAC-SHA1')

      @store.store_association(@_dumb_key, assoc)

      signed = Message.from_post_args({
            'foo' => 'bar',
            'apple' => 'orange',
            'openid.sig' => "d71xlHtqnq98DonoSgoK/nD+QRM=",
            })

      verified = nil
      silence_logging {
        verified = @signatory.verify(assoc_handle, signed)
      }

      assert(!verified)
      #assert(@messages)
    end

    def test_getAssoc
      assoc_handle = makeAssoc(true)
      assoc = @signatory.get_association(assoc_handle, true)
      assert(assoc)
      assert_equal(assoc.handle, assoc_handle)
      # @failIf(@messages, @messages)
    end

    def test_getAssocExpired
      assoc_handle = makeAssoc(true, -10)
      assoc = nil
      silence_logging {
        assoc = @signatory.get_association(assoc_handle, true)
      }
      assert(!assoc, assoc)
      # assert(@messages)
    end

    def test_getAssocInvalid
      ah = 'no-such-handle'
      silence_logging {
        assert_equal(
                     @signatory.get_association(ah, false), nil)
      }
      # assert(!@messages, @messages)
    end

    def test_getAssocDumbVsNormal
      # getAssociation(dumb=False) cannot get a dumb assoc
      assoc_handle = makeAssoc(true)
      silence_logging {
        assert_equal(
                     @signatory.get_association(assoc_handle, false), nil)
      }
      # @failIf(@messages, @messages)
    end

    def test_getAssocNormalVsDumb
      # getAssociation(dumb=True) cannot get a shared assoc
      #
      # From "Verifying Directly with the OpenID Provider"::
      #
      #   An OP MUST NOT verify signatures for associations that have shared
      #   MAC keys.
      assoc_handle = makeAssoc(false)
      silence_logging {
        assert_equal(
                     @signatory.get_association(assoc_handle, true), nil)
      }
      # @failIf(@messages, @messages)
    end

    def test_createAssociation
      assoc = @signatory.create_association(false)
      silence_logging {
        assert(@signatory.get_association(assoc.handle, false))
      }
      # @failIf(@messages, @messages)
    end

    def makeAssoc(dumb, lifetime=60)
      assoc_handle = '{bling}'
      assoc = Association.from_expires_in(lifetime, assoc_handle,
                                          'sekrit', 'HMAC-SHA1')

      silence_logging {
        @store.store_association(((dumb and @_dumb_key) or @_normal_key), assoc)
      }

      return assoc_handle
    end

    def test_invalidate
      assoc_handle = '-squash-'
      assoc = Association.from_expires_in(60, assoc_handle,
                                          'sekrit', 'HMAC-SHA1')

      silence_logging {
        @store.store_association(@_dumb_key, assoc)
        assoc = @signatory.get_association(assoc_handle, true)
        assert(assoc)
        assoc = @signatory.get_association(assoc_handle, true)
        assert(assoc)
        @signatory.invalidate(assoc_handle, true)
        assoc = @signatory.get_association(assoc_handle, true)
        assert(!assoc)
      }
      # @failIf(@messages, @messages)
    end
  end

  class RunthroughTestCase < Test::Unit::TestCase
    def setup
      @store = Store::Memory.new
      @server = Server::Server.new(@store, "http://example.com/openid/server")
    end

    def test_openid1_assoc_checkid
      assoc_args = {'openid.mode' => 'associate',
                    'openid.assoc_type' => 'HMAC-SHA1'}
      areq = @server.decode_request(assoc_args)
      aresp = @server.handle_request(areq)
      
      amess = aresp.fields
      assert(amess.is_openid1)
      ahandle = amess.get_arg(OPENID_NS, 'assoc_handle')
      assert(ahandle)
      assoc = @store.get_association('http://localhost/|normal', ahandle)
      assert(assoc.is_a?(Association))


      checkid_args = {'openid.mode' => 'checkid_setup',
                      'openid.return_to' => 'http://example.com/openid/consumer',
                      'openid.assoc_handle' => ahandle,
                      'openid.identity' => 'http://foo.com/'}
      
      cireq = @server.decode_request(checkid_args)
      ciresp = cireq.answer(true)

      signed_resp = @server.signatory.sign(ciresp)

      assert_equal(assoc.get_message_signature(signed_resp.fields),
                   signed_resp.fields.get_arg(OPENID_NS, 'sig'))
                   
      assert(assoc.check_message_signature(signed_resp.fields))
    end

  end
end
