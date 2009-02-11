
require 'test/unit'
require 'openid/yadis/xrires'

module OpenID
  module Yadis

    class XRDSFetcher
      def initialize(results)
        @results = results
      end

      def fetch(url, body=nil, headers=nil, redirect_limit=nil)
        if !@results.empty?
          return @results.shift
        end

        nil
      end
    end

    class ProxyQueryTestCase < Test::Unit::TestCase
      def setup
        @proxy_url = 'http://xri.example.com/'
        @proxy = XRI::ProxyResolver.new(@proxy_url)
        @servicetype = 'xri://+i-service*(+forwarding)*($v*1.0)'
        @servicetype_enc = 'xri%3A%2F%2F%2Bi-service%2A%28%2Bforwarding%29%2A%28%24v%2A1.0%29'
      end

      def test_proxy_url
        st = @servicetype
        ste = @servicetype_enc
        args_esc = "_xrd_r=application%2Fxrds%2Bxml&_xrd_t=" + ste
        pqu = @proxy.method('query_url')
        h = @proxy_url

        assert_equal(h + '=foo?' + args_esc, pqu.call('=foo', st))
        assert_equal(h + '=foo/bar?baz&' + args_esc,
                     pqu.call('=foo/bar?baz', st))
        assert_equal(h + '=foo/bar?baz=quux&' + args_esc,
                     pqu.call('=foo/bar?baz=quux', st))
        assert_equal(h + '=foo/bar?mi=fa&so=la&' + args_esc,
                     pqu.call('=foo/bar?mi=fa&so=la', st))

        # With no service endpoint selection.
        args_esc = "_xrd_r=application%2Fxrds%2Bxml%3Bsep%3Dfalse"
        assert_equal(h + '=foo?' + args_esc, pqu.call('=foo', nil))
      end

      def test_proxy_url_qmarks
        st = @servicetype
        ste = @servicetype_enc
        args_esc = "_xrd_r=application%2Fxrds%2Bxml&_xrd_t=" + ste
        pqu = @proxy.method('query_url')
        h = @proxy_url

        assert_equal(h + '=foo/bar??' + args_esc, pqu.call('=foo/bar?', st))
        assert_equal(h + '=foo/bar????' + args_esc,
                     pqu.call('=foo/bar???', st))
      end
    end
  end
end
