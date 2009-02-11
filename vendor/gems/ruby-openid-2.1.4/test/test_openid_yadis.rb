
require 'test/unit'
require 'openid/consumer/discovery'
require 'openid/yadis/services'

module OpenID

  XRDS_BOILERPLATE = <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<xrds:XRDS xmlns:xrds="xri://$xrds"
           xmlns="xri://$xrd*($v*2.0)"
           xmlns:openid="http://openid.net/xmlns/1.0">
    <XRD>
%s
    </XRD>
</xrds:XRDS>
EOF

  def self.mkXRDS(services)
    return sprintf(XRDS_BOILERPLATE, services)
  end

  def self.mkService(uris=nil, type_uris=nil, local_id=nil, dent="        ")
    chunks = [dent, "<Service>\n"]
    dent2 = dent + "    "
    if type_uris
      type_uris.each { |type_uri|
        chunks += [dent2 + "<Type>", type_uri, "</Type>\n"]
      }
    end

    if uris
      uris.each { |uri|
        if uri.is_a?(Array)
          uri, prio = uri
        else
          prio = nil
        end

        chunks += [dent2, "<URI"]
        if !prio.nil?
          chunks += [" priority='", str(prio), "'"]
        end
        chunks += [">", uri, "</URI>\n"]
      }
    end

    if local_id
      chunks += [dent2, "<openid:Delegate>", local_id, "</openid:Delegate>\n"]
    end

    chunks += [dent, "</Service>\n"]

    return chunks.join("")
  end

  # Different sets of server URLs for use in the URI tag
  SERVER_URL_OPTIONS = [
                        [], # This case should not generate an endpoint object
                        ['http://server.url/'],
                        ['https://server.url/'],
                        ['https://server.url/', 'http://server.url/'],
                        ['https://server.url/',
                         'http://server.url/',
                         'http://example.server.url/'],
                       ]

  # Used for generating test data
  def OpenID.subsets(l)
    subsets_list = [[]]
    l.each { |x|
      subsets_list += subsets_list.collect { |t| [x] + t }
    }

    return subsets_list
  end

  # A couple of example extension type URIs. These are not at all
  # official, but are just here for testing.
  EXT_TYPES = [
               'http://janrain.com/extension/blah',
               'http://openid.net/sreg/1.0',
              ]

  # Range of valid Delegate tag values for generating test data
  LOCAL_ID_OPTIONS = [
                      nil,
                      'http://vanity.domain/',
                      'https://somewhere/yadis/',
                     ]

  class OpenIDYadisTest
    def initialize(uris, type_uris, local_id)
      super()
      @uris = uris
      @type_uris = type_uris
      @local_id = local_id

      @yadis_url = 'http://unit.test/'

      # Create an XRDS document to parse
      services = OpenID.mkService(@uris,
                                  @type_uris,
                                  @local_id)
      @xrds = OpenID.mkXRDS(services)
    end

    def runTest(testcase)
      # Parse into endpoint objects that we will check
      endpoints = Yadis.apply_filter(@yadis_url, @xrds, OpenIDServiceEndpoint)

      # make sure there are the same number of endpoints as URIs. This
      # assumes that the type_uris contains at least one OpenID type.
      testcase.assert_equal(@uris.length, endpoints.length)

      # So that we can check equality on the endpoint types
      type_uris = @type_uris.dup
      type_uris.sort!

      seen_uris = []
      endpoints.each { |endpoint|
        seen_uris << endpoint.server_url

        # All endpoints will have same yadis_url
        testcase.assert_equal(@yadis_url, endpoint.claimed_id)

        # and local_id
        testcase.assert_equal(@local_id, endpoint.local_id)

        # and types
        actual_types = endpoint.type_uris.dup
        actual_types.sort!
        testcase.assert_equal(type_uris, actual_types, actual_types.inspect)
      }

      # So that they will compare equal, because we don't care what
      # order they are in
      seen_uris.sort!
      uris = @uris.dup
      uris.sort!

      # Make sure we saw all URIs, and saw each one once
      testcase.assert_equal(uris, seen_uris)
    end
  end

  class OpenIDYadisTests < Test::Unit::TestCase
    def test_openid_yadis
      data = []

      # All valid combinations of Type tags that should produce an
      # OpenID endpoint
      type_uri_options = []

      OpenID.subsets([OPENID_1_0_TYPE, OPENID_1_1_TYPE]).each { |ts|
        OpenID.subsets(EXT_TYPES).each { |exts|
          if !ts.empty?
            type_uri_options << exts + ts
          end
        }
      }

      # All combinations of valid URIs, Type URIs and Delegate tags
      SERVER_URL_OPTIONS.each { |uris|
        type_uri_options.each { |type_uris|
          LOCAL_ID_OPTIONS.each { |local_id|
            data << [uris, type_uris, local_id]
          }
        }
      }

      data.each { |args|
        t = OpenIDYadisTest.new(*args)
        t.runTest(self)
      }
    end
  end
end
