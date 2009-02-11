
require 'testutil'
require 'util'

require 'test/unit'
require 'openid/fetchers'
require 'openid/yadis/discovery'
require 'openid/consumer/discovery'
require 'openid/yadis/xrires'
require 'openid/yadis/xri'
require 'openid/message'
require 'openid/util'

### Tests for conditions that trigger DiscoveryFailure

module OpenID
  class SimpleMockFetcher
    def initialize(test, responses)
      @test = test
      @responses = responses.dup
    end

    def fetch(url, body=nil, headers=nil, limit=nil)
      response = @responses.shift
      @test.assert(body.nil?)
      @test.assert_equal(response.final_url, url)
      return response
    end
  end

  class TestDiscoveryFailure < Test::Unit::TestCase
    def initialize(*args)
      super(*args)

      @responses = [
                    [HTTPResponse._from_raw_data(nil, nil, {}, 'http://network.error/')],
                    [HTTPResponse._from_raw_data(404, nil, {}, 'http://not.found/')],
                    [HTTPResponse._from_raw_data(400, nil, {}, 'http://bad.request/')],
                    [HTTPResponse._from_raw_data(500, nil, {}, 'http://server.error/')],
                    [HTTPResponse._from_raw_data(200, nil, {'x-xrds-location' => 'http://xrds.missing/'},
                                                 'http://header.found/'),
                     HTTPResponse._from_raw_data(404, nil, {}, 'http://xrds.missing/')],
                    ]
    end

    def test_discovery_failure

      @responses.each { |response_set|
        @url = response_set[0].final_url
        OpenID.fetcher = SimpleMockFetcher.new(self, response_set)
      
        expected_status = response_set[-1].code
        begin
          OpenID.discover(@url)
        rescue DiscoveryFailure => why
          assert_equal(why.http_response.code, expected_status)
        else
          flunk('Did not raise DiscoveryFailure')
        end

        OpenID.fetcher = nil
      }
    end
  end

  ### Tests for raising/catching exceptions from the fetcher through
  ### the discover function

  class ErrorRaisingFetcher
    # Just raise an exception when fetch is called

    def initialize(thing_to_raise)
      @thing_to_raise = thing_to_raise
    end

    def fetch(url, body=nil, headers=nil, limit=nil)
      raise @thing_to_raise
    end
  end

  class DidFetch < Exception
    # Custom exception just to make sure it's not handled differently
  end

  class TestFetchException < Test::Unit::TestCase
    # Discovery should only raise DiscoveryFailure

    def initialize(*args)
      super(*args)

      @cases = [
                DidFetch.new(),
                Exception.new(),
                ArgumentError.new(),
                RuntimeError.new(),
               ]
    end

    def test_fetch_exception
      @cases.each { |exc|
        OpenID.fetcher = ErrorRaisingFetcher.new(exc)
        assert_raises(DiscoveryFailure) {
          OpenID.discover('http://doesnt.matter/')
        }
        OpenID.fetcher = nil
      }
    end
  end

  ### Tests for openid.consumer.discover.discover

  class TestNormalization < Test::Unit::TestCase
    def test_addingProtocol
      f = ErrorRaisingFetcher.new(RuntimeError.new())
      OpenID.fetcher = f

      begin
        OpenID.discover('users.stompy.janrain.com:8000/x')
      rescue DiscoveryFailure => why
        assert why.to_s.match("Failed to fetch")
      rescue RuntimeError
      end

      OpenID.fetcher = nil
    end
  end

  class DiscoveryMockFetcher
    def initialize(documents)
      @redirect = nil
      @documents = documents
      @fetchlog = []
    end

    def fetch(url, body=nil, headers=nil, limit=nil)
      @fetchlog << [url, body, headers]
      if @redirect
        final_url = @redirect
      else
        final_url = url
      end

      begin
        ctype, body = @documents.fetch(url)
      rescue IndexError
        status = 404
        ctype = 'text/plain'
        body = ''
      else
        status = 200
      end

      return HTTPResponse._from_raw_data(status, body, {'content-type' => ctype}, final_url)
    end
  end

  class BaseTestDiscovery < Test::Unit::TestCase
    attr_accessor :id_url, :fetcher_class

    def initialize(*args)
      super(*args)
      @id_url = "http://someuser.unittest/"
      @documents = {}
      @fetcher_class = DiscoveryMockFetcher
    end

    def _checkService(s, server_url, claimed_id=nil,
                      local_id=nil, canonical_id=nil,
                      types=nil, used_yadis=false,
                      display_identifier=nil)
      assert_equal(server_url, s.server_url)
      if types == ['2.0 OP']
        assert(!claimed_id)
        assert(!local_id)
        assert(!s.claimed_id)
        assert(!s.local_id)
        assert(!s.get_local_id())
        assert(!s.compatibility_mode())
        assert(s.is_op_identifier())
        assert_equal(s.preferred_namespace(),
                     OPENID_2_0_MESSAGE_NS)
      else
        assert_equal(claimed_id, s.claimed_id)
        assert_equal(local_id, s.get_local_id())
      end

      if used_yadis
        assert(s.used_yadis, "Expected to use Yadis")
      else
        assert(!s.used_yadis,
               "Expected to use old-style discovery")
      end

      openid_types = {
        '1.1' => OPENID_1_1_TYPE,
        '1.0' => OPENID_1_0_TYPE,
        '2.0' => OPENID_2_0_TYPE,
        '2.0 OP' => OPENID_IDP_2_0_TYPE,
      }

      type_uris = types.collect { |t| openid_types[t] }

      assert_equal(type_uris, s.type_uris)
      assert_equal(canonical_id, s.canonical_id)

      if canonical_id.nil?
        assert_equal(claimed_id, s.display_identifier)
      else
        assert_equal(display_identifier, s.display_identifier)
      end
    end

    def setup
      # @documents = @documents.dup
      @fetcher = @fetcher_class.new(@documents)
      OpenID.fetcher = @fetcher
    end

    def teardown
      OpenID.fetcher = nil
    end

    def test_blank
      # XXX to avoid > 0 test requirement
    end
  end

#   def readDataFile(filename):
#     module_directory = os.path.dirname(os.path.abspath(__file__))
#     filename = os.path.join(
#         module_directory, 'data', 'test_discover', filename)
#     return file(filename).read()

  class TestDiscovery < BaseTestDiscovery
    include TestDataMixin

    def _discover(content_type, data,
                  expected_services, expected_id=nil)
      if expected_id.nil?
        expected_id = @id_url
      end

      @documents[@id_url] = [content_type, data]
      id_url, services = OpenID.discover(@id_url)

      assert_equal(expected_services, services.length)
      assert_equal(expected_id, id_url)
      return services
    end

    def test_404
      assert_raise(DiscoveryFailure) {
        OpenID.discover(@id_url + '/404')
      }
    end

    def test_noOpenID
      services = _discover('text/plain',
                           "junk", 0)

      services = _discover(
                           'text/html',
                           read_data_file('test_discover/openid_no_delegate.html', false),
                           1)

      _checkService(
                    services[0],
                    "http://www.myopenid.com/server",
                    @id_url,
                    @id_url,
                    nil,
                    ['1.1'],
                    false)
    end

    def test_malformed_meta_tag
      @id_url = "http://user.myopenid.com/"

      services = _discover(
                           'text/html',
                           read_data_file('test_discover/malformed_meta_tag.html', false),
                           2)

      _checkService(
                    services[0],
                    "http://www.myopenid.com/server",
                    @id_url,
                    @id_url,
                    nil,
                    ['2.0'],
                    false)

      _checkService(
                    services[1],
                    "http://www.myopenid.com/server",
                    @id_url,
                    @id_url,
                    nil,
                    ['1.1'],
                    false)
    end

    def test_html1
      services = _discover('text/html',
                           read_data_file('test_discover/openid.html', false),
                           1)

      _checkService(services[0],
                    "http://www.myopenid.com/server",
                    @id_url,
                    'http://smoker.myopenid.com/',
                    nil,
                    ['1.1'],
                    false)
    end

    def test_html1Fragment
      # Ensure that the Claimed Identifier does not have a fragment if
      # one is supplied in the User Input.
      content_type = 'text/html'
      data = read_data_file('test_discover/openid.html', false)
      expected_services = 1

      @documents[@id_url] = [content_type, data]
      expected_id = @id_url
      @id_url = @id_url + '#fragment'
      id_url, services = OpenID.discover(@id_url)

      assert_equal(expected_services, services.length)
      assert_equal(expected_id, id_url)

      _checkService(services[0],
                    "http://www.myopenid.com/server",
                    expected_id,
                    'http://smoker.myopenid.com/',
                    nil,
                    ['1.1'],
                    false)
    end

    def test_html2
      services = _discover('text/html',
                           read_data_file('test_discover/openid2.html', false),
                           1)

      _checkService(services[0],
                    "http://www.myopenid.com/server",
                    @id_url,
                    'http://smoker.myopenid.com/',
                    nil,
                    ['2.0'],
                    false)
    end

    def test_html1And2
      services = _discover(
                           'text/html',
                           read_data_file('test_discover/openid_1_and_2.html', false),
                           2)

      services.zip(['2.0', '1.1']).each { |s, t|
          _checkService(s,
                        "http://www.myopenid.com/server",
                        @id_url,
                        'http://smoker.myopenid.com/',
                        nil,
                        [t],
                        false)
      }
    end

    def test_yadisEmpty
      services = _discover('application/xrds+xml',
                           read_data_file('test_discover/yadis_0entries.xml', false),
                           0)
    end

    def test_htmlEmptyYadis
      # HTML document has discovery information, but points to an
      # empty Yadis document.  The XRDS document pointed to by
      # "openid_and_yadis.html"
      @documents[@id_url + 'xrds'] = ['application/xrds+xml',
                                      read_data_file('test_discover/yadis_0entries.xml', false)]

      services = _discover('text/html',
                           read_data_file('test_discover/openid_and_yadis.html', false),
                           1)

      _checkService(services[0],
                    "http://www.myopenid.com/server",
                    @id_url,
                    'http://smoker.myopenid.com/',
                    nil,
                    ['1.1'],
                    false)
    end

    def test_yadis1NoDelegate
      services = _discover('application/xrds+xml',
                           read_data_file('test_discover/yadis_no_delegate.xml', false),
                           1)

      _checkService(services[0],
                    "http://www.myopenid.com/server",
                    @id_url,
                    @id_url,
                    nil,
                    ['1.0'],
                    true)
    end

    def test_yadis2NoLocalID
      services = _discover('application/xrds+xml',
                           read_data_file('test_discover/openid2_xrds_no_local_id.xml', false),
                           1)

      _checkService(services[0],
                    "http://www.myopenid.com/server",
                    @id_url,
                    @id_url,
                    nil,
                    ['2.0'],
                    true)
    end

    def test_yadis2
      services = _discover('application/xrds+xml',
                           read_data_file('test_discover/openid2_xrds.xml', false),
                           1)

      _checkService(services[0],
                    "http://www.myopenid.com/server",
                    @id_url,
                    'http://smoker.myopenid.com/',
                    nil,
                    ['2.0'],
                    true)
    end

    def test_yadis2OP
      services = _discover('application/xrds+xml',
                           read_data_file('test_discover/yadis_idp.xml', false),
                           1)

      _checkService(services[0],
                    "http://www.myopenid.com/server",
                    nil, nil, nil,
                    ['2.0 OP'],
                    true)
    end

    def test_yadis2OPDelegate
      # The delegate tag isn't meaningful for OP entries.
      services = _discover('application/xrds+xml',
                           read_data_file('test_discover/yadis_idp_delegate.xml', false),
                           1)

      _checkService(services[0],
                    "http://www.myopenid.com/server",
                    nil, nil, nil,
                    ['2.0 OP'],
                    true)
    end

    def test_yadis2BadLocalID
      assert_raise(DiscoveryFailure) {
        _discover('application/xrds+xml',
                  read_data_file('test_discover/yadis_2_bad_local_id.xml', false),
                  1)
      }
    end

    def test_yadis1And2
      services = _discover('application/xrds+xml',
                           read_data_file('test_discover/openid_1_and_2_xrds.xml', false),
                           1)

      _checkService(services[0],
                    "http://www.myopenid.com/server",
                    @id_url,
                    'http://smoker.myopenid.com/',
                    nil,
                    ['2.0', '1.1'],
                    true)
    end

    def test_yadis1And2BadLocalID
      assert_raise(DiscoveryFailure) {
        _discover('application/xrds+xml',
                  read_data_file('test_discover/openid_1_and_2_xrds_bad_delegate.xml', false),
                  1)
      }
    end
  end

  class MockFetcherForXRIProxy

    def initialize(documents, proxy_url=Yadis::XRI::ProxyResolver::DEFAULT_PROXY)
      @documents = documents
      @fetchlog = []
      @proxy_url = nil
    end

    def fetch(url, body=nil, headers=nil, limit=nil)
      @fetchlog << [url, body, headers]

      u = URI::parse(url)
      proxy_host = u.host
      xri = u.path
      query = u.query

      if !headers and !query
        raise ArgumentError.new("No headers or query; you probably didn't " +
                                "mean to do that.")
      end

      if xri.starts_with?('/')
        xri = xri[1..-1]
      end

      begin
        ctype, body = @documents.fetch(xri)
      rescue IndexError
        status = 404
        ctype = 'text/plain'
        body = ''
      else
        status = 200
      end

      return HTTPResponse._from_raw_data(status, body,
                                         {'content-type' => ctype}, url)
    end
  end

  class TestXRIDiscovery < BaseTestDiscovery

    include TestDataMixin
    include TestUtil

    def initialize(*args)
      super(*args)

      @fetcher_class = MockFetcherForXRIProxy

      @documents = {'=smoker' => ['application/xrds+xml',
                                  read_data_file('test_discover/yadis_2entries_delegate.xml', false)],
        '=smoker*bad' => ['application/xrds+xml',
                          read_data_file('test_discover/yadis_another_delegate.xml', false)]}
    end

    def test_xri
      user_xri, services = OpenID.discover_xri('=smoker')

      _checkService(services[0],
                    "http://www.myopenid.com/server",
                    Yadis::XRI.make_xri("=!1000"),
                    'http://smoker.myopenid.com/',
                    Yadis::XRI.make_xri("=!1000"),
                    ['1.0'],
                    true,
                    '=smoker')

      _checkService(services[1],
                    "http://www.livejournal.com/openid/server.bml",
                    Yadis::XRI.make_xri("=!1000"),
                    'http://frank.livejournal.com/',
                    Yadis::XRI.make_xri("=!1000"),
                    ['1.0'],
                    true,
                    '=smoker')
    end

    def test_xri_normalize
      user_xri, services = OpenID.discover_xri('xri://=smoker')

      _checkService(services[0],
                    "http://www.myopenid.com/server",
                    Yadis::XRI.make_xri("=!1000"),
                    'http://smoker.myopenid.com/',
                    Yadis::XRI.make_xri("=!1000"),
                    ['1.0'],
                    true,
                    '=smoker')

      _checkService(services[1],
                    "http://www.livejournal.com/openid/server.bml",
                    Yadis::XRI.make_xri("=!1000"),
                    'http://frank.livejournal.com/',
                    Yadis::XRI.make_xri("=!1000"),
                    ['1.0'],
                    true,
                    '=smoker')
    end

    def test_xriNoCanonicalID
      silence_logging {
        user_xri, services = OpenID.discover_xri('=smoker*bad')
        assert(services.empty?)
      }
    end

    def test_useCanonicalID
      # When there is no delegate, the CanonicalID should be used with
      # XRI.
      endpoint = OpenIDServiceEndpoint.new()
      endpoint.claimed_id = Yadis::XRI.make_xri("=!1000")
      endpoint.canonical_id = Yadis::XRI.make_xri("=!1000")
      assert_equal(endpoint.get_local_id, Yadis::XRI.make_xri("=!1000"))
    end
  end

  class TestXRIDiscoveryIDP < BaseTestDiscovery
    include TestDataMixin

    def initialize(*args)
      super(*args)

      @fetcher_class = MockFetcherForXRIProxy

      @documents = {'=smoker' => ['application/xrds+xml',
                                  read_data_file('test_discover/yadis_2entries_idp.xml', false)] }
    end

    def test_xri
      user_xri, services = OpenID.discover_xri('=smoker')
      assert(!services.empty?, "Expected services, got zero")
      assert_equal(services[0].server_url,
                   "http://www.livejournal.com/openid/server.bml")
    end
  end

  class TestPreferredNamespace < Test::Unit::TestCase
    def initialize(*args)
      super(*args)

      @cases = [
               [OPENID1_NS, []],
               [OPENID1_NS, ['http://jyte.com/']],
               [OPENID1_NS, [OPENID_1_0_TYPE]],
               [OPENID1_NS, [OPENID_1_1_TYPE]],
               [OPENID2_NS, [OPENID_2_0_TYPE]],
               [OPENID2_NS, [OPENID_IDP_2_0_TYPE]],
               [OPENID2_NS, [OPENID_2_0_TYPE,
                             OPENID_1_0_TYPE]],
               [OPENID2_NS, [OPENID_1_0_TYPE,
                             OPENID_2_0_TYPE]],
              ]
    end

    def test_preferred_namespace

      @cases.each { |expected_ns, type_uris|
        endpoint = OpenIDServiceEndpoint.new()
        endpoint.type_uris = type_uris
        actual_ns = endpoint.preferred_namespace()
        assert_equal(actual_ns, expected_ns)
      }
    end
  end

  class TestIsOPIdentifier < Test::Unit::TestCase
    def setup
      @endpoint = OpenIDServiceEndpoint.new()
    end

    def test_none
      assert(!@endpoint.is_op_identifier())
    end

    def test_openid1_0
      @endpoint.type_uris = [OPENID_1_0_TYPE]
      assert(!@endpoint.is_op_identifier())
    end

    def test_openid1_1
      @endpoint.type_uris = [OPENID_1_1_TYPE]
      assert(!@endpoint.is_op_identifier())
    end

    def test_openid2
      @endpoint.type_uris = [OPENID_2_0_TYPE]
      assert(!@endpoint.is_op_identifier())
    end

    def test_openid2OP
      @endpoint.type_uris = [OPENID_IDP_2_0_TYPE]
      assert(@endpoint.is_op_identifier())
    end

    def test_multipleMissing
      @endpoint.type_uris = [OPENID_2_0_TYPE,
                             OPENID_1_0_TYPE]
      assert(!@endpoint.is_op_identifier())
    end

    def test_multiplePresent
      @endpoint.type_uris = [OPENID_2_0_TYPE,
                             OPENID_1_0_TYPE,
                             OPENID_IDP_2_0_TYPE]
      assert(@endpoint.is_op_identifier())
    end
  end

  class TestFromOPEndpointURL < Test::Unit::TestCase
    def setup
      @op_endpoint_url = 'http://example.com/op/endpoint'
      @endpoint = OpenIDServiceEndpoint.from_op_endpoint_url(@op_endpoint_url)
    end

    def test_isOPEndpoint
      assert(@endpoint.is_op_identifier())
    end

    def test_noIdentifiers
      assert_equal(@endpoint.get_local_id, nil)
      assert_equal(@endpoint.claimed_id, nil)
    end

    def test_compatibility
      assert(!@endpoint.compatibility_mode())
    end

    def test_canonical_id
      assert_equal(@endpoint.canonical_id, nil)
    end

    def test_serverURL
      assert_equal(@endpoint.server_url, @op_endpoint_url)
    end
  end

  class TestDiscoverFunction < Test::Unit::TestCase
    def test_discover_function
      # XXX these were all different tests in python, but they're
      # combined here so I only have to use with_method_overridden
      # once.
      discoverXRI = Proc.new { |identifier|
        return 'XRI'
      }

      discoverURI = Proc.new { |identifier|
        return 'URI'
      }

      OpenID.extend(OverrideMethodMixin)

      OpenID.with_method_overridden(:discover_uri, discoverURI) do
        OpenID.with_method_overridden(:discover_xri, discoverXRI) do
          assert_equal('URI', OpenID.discover('http://woo!'))
          assert_equal('URI', OpenID.discover('not a URL or XRI'))
          assert_equal('XRI', OpenID.discover('xri://=something'))
          assert_equal('XRI', OpenID.discover('=something'))
        end
      end
    end
  end

  class TestEndpointSupportsType < Test::Unit::TestCase
    def setup
      @endpoint = OpenIDServiceEndpoint.new()
    end

    def failUnlessSupportsOnly(*types)
      ['foo',
       OPENID_1_1_TYPE,
       OPENID_1_0_TYPE,
       OPENID_2_0_TYPE,
       OPENID_IDP_2_0_TYPE].each { |t|
        if types.member?(t)
          assert(@endpoint.supports_type(t),
                 sprintf("Must support %s", t))
        else
          assert(!@endpoint.supports_type(t),
                 sprintf("Shouldn't support %s", t))
        end
      }
    end

    def test_supportsNothing
      failUnlessSupportsOnly()
    end

    def test_openid2
      @endpoint.type_uris = [OPENID_2_0_TYPE]
      failUnlessSupportsOnly(OPENID_2_0_TYPE)
    end

    def test_openid2provider
      @endpoint.type_uris = [OPENID_IDP_2_0_TYPE]
      failUnlessSupportsOnly(OPENID_IDP_2_0_TYPE,
                             OPENID_2_0_TYPE)
    end

    def test_openid1_0
      @endpoint.type_uris = [OPENID_1_0_TYPE]
      failUnlessSupportsOnly(OPENID_1_0_TYPE)
    end

    def test_openid1_1
      @endpoint.type_uris = [OPENID_1_1_TYPE]
      failUnlessSupportsOnly(OPENID_1_1_TYPE)
    end

    def test_multiple
      @endpoint.type_uris = [OPENID_1_1_TYPE,
                             OPENID_2_0_TYPE]
      failUnlessSupportsOnly(OPENID_1_1_TYPE,
                             OPENID_2_0_TYPE)
    end

    def test_multipleWithProvider
      @endpoint.type_uris = [OPENID_1_1_TYPE,
                             OPENID_2_0_TYPE,
                             OPENID_IDP_2_0_TYPE]
      failUnlessSupportsOnly(OPENID_1_1_TYPE,
                             OPENID_2_0_TYPE,
                             OPENID_IDP_2_0_TYPE)
    end
  end

  class TestEndpointDisplayIdentifier < Test::Unit::TestCase
    def test_strip_fragment
      @endpoint = OpenIDServiceEndpoint.new()
      @endpoint.claimed_id = 'http://recycled.invalid/#123'
      assert_equal 'http://recycled.invalid/', @endpoint.display_identifier
    end
  end


  class TestNormalizeURL < Test::Unit::TestCase
    def test_no_host
      assert_raise(DiscoveryFailure) {
        OpenID::normalize_url('http:///too-many.invalid/slashes')
      }
    end
  end
end
