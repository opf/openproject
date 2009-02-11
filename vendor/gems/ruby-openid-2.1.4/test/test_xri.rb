require 'test/unit'
require 'openid/yadis/xri'

module OpenID

  module Yadis

    class XriDiscoveryTestCase < Test::Unit::TestCase

      def test_isXRI?
        assert_equal(:xri, XRI.identifier_scheme('=john.smith'))
        assert_equal(:xri, XRI.identifier_scheme('@smiths/john'))
        assert_equal(:xri, XRI.identifier_scheme('xri://=john'))
        assert_equal(:xri, XRI.identifier_scheme('@ootao*test1'))
        assert_equal(:uri, XRI.identifier_scheme('smoker.myopenid.com'))
        assert_equal(:uri, XRI.identifier_scheme('http://smoker.myopenid.com'))
        assert_equal(:uri, XRI.identifier_scheme('https://smoker.myopenid.com'))
      end
    end

    class XriEscapingTestCase < Test::Unit::TestCase
      def test_escaping_percents
        assert_equal('@example/abc%252Fd/ef', 
                     XRI.escape_for_iri('@example/abc%2Fd/ef'))
      end

      def test_escaping_xref
        # no escapes
        assert_equal('@example/foo/(@bar)',
                     XRI.escape_for_iri('@example/foo/(@bar)'))
        # escape slashes
        assert_equal('@example/foo/(@bar%2Fbaz)',
                     XRI.escape_for_iri('@example/foo/(@bar/baz)'))
        # escape query ? and fragment #
        assert_equal('@example/foo/(@baz%3Fp=q%23r)?i=j#k',
                     XRI.escape_for_iri('@example/foo/(@baz?p=q#r)?i=j#k'))
      end
    end

    class XriTransformationTestCase < Test::Unit::TestCase
      def test_to_iri_normal
        assert_equal('xri://@example', XRI.to_iri_normal('@example'))
      end
      # iri_to_url:
      #   various ucschar to hex
    end
  end
end
