require "openid/kvpost"
require "openid/kvform"
require "openid/message"
require "test/unit"
require 'testutil'

module OpenID
  class KVPostTestCase < Test::Unit::TestCase
    include FetcherMixin

    def mk_resp(status, resp_hash)
      return MockResponse.new(status, Util.dict_to_kv(resp_hash))
    end

    def test_msg_from_http_resp_success
      resp = mk_resp(200, {'mode' => 'seitan'})
      msg = Message.from_http_response(resp, 'http://invalid/')
      assert_equal({'openid.mode' => 'seitan'}, msg.to_post_args)
    end

    def test_400
      args = {'error' => 'I ate too much cheese',
        'error_code' => 'sadness'}
      resp = mk_resp(400, args)
      begin
        val = Message.from_http_response(resp, 'http://invalid/')
      rescue ServerError => why
        assert_equal(why.error_text, 'I ate too much cheese')
        assert_equal(why.error_code, 'sadness')
        assert_equal(why.message.to_args, args)
      else
        fail("Expected exception. Got: #{val}")
      end
    end

    def test_500
      args = {'error' => 'I ate too much cheese',
        'error_code' => 'sadness'}
      resp = mk_resp(500, args)
      assert_raises(HTTPStatusError) {
        Message.from_http_response(resp, 'http://invalid')
      }
    end

    def make_kv_post_with_response(status, args)
      resp = mk_resp(status, args)
      mock_fetcher = Class.new do
        define_method(:fetch) do |url, body, xxx, yyy|
          resp
        end
      end
      fetcher = mock_fetcher.new

      with_fetcher(mock_fetcher.new) do
        OpenID.make_kv_post(Message.from_openid_args(args), 'http://invalid/')
      end
    end

    def test_make_kv_post
      assert_raises(HTTPStatusError) {
        make_kv_post_with_response(500, {})
      }
    end
  end
end
