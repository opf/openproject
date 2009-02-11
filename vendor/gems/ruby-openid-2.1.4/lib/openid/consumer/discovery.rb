# Functions to discover OpenID endpoints from identifiers.

require 'uri'
require 'openid/util'
require 'openid/fetchers'
require 'openid/urinorm'
require 'openid/message'
require 'openid/yadis/discovery'
require 'openid/yadis/xrds'
require 'openid/yadis/xri'
require 'openid/yadis/services'
require 'openid/yadis/filters'
require 'openid/consumer/html_parse'
require 'openid/yadis/xrires'

module OpenID

  OPENID_1_0_NS = 'http://openid.net/xmlns/1.0'
  OPENID_IDP_2_0_TYPE = 'http://specs.openid.net/auth/2.0/server'
  OPENID_2_0_TYPE = 'http://specs.openid.net/auth/2.0/signon'
  OPENID_1_1_TYPE = 'http://openid.net/signon/1.1'
  OPENID_1_0_TYPE = 'http://openid.net/signon/1.0'

  OPENID_1_0_MESSAGE_NS = OPENID1_NS
  OPENID_2_0_MESSAGE_NS = OPENID2_NS

  # Object representing an OpenID service endpoint.
  class OpenIDServiceEndpoint

    # OpenID service type URIs, listed in order of preference.  The
    # ordering of this list affects yadis and XRI service discovery.
    OPENID_TYPE_URIS = [
        OPENID_IDP_2_0_TYPE,

        OPENID_2_0_TYPE,
        OPENID_1_1_TYPE,
        OPENID_1_0_TYPE,
        ]

    # the verified identifier.
    attr_accessor :claimed_id

    # For XRI, the persistent identifier.
    attr_accessor :canonical_id

    attr_accessor :server_url, :type_uris, :local_id, :used_yadis

    def initialize
      @claimed_id = nil
      @server_url = nil
      @type_uris = []
      @local_id = nil
      @canonical_id = nil
      @used_yadis = false # whether this came from an XRDS
      @display_identifier = nil
    end

    def display_identifier
      return @display_identifier if @display_identifier

      return @claimed_id if @claimed_id.nil? 

      begin
        parsed_identifier = URI.parse(@claimed_id)
      rescue URI::InvalidURIError
        raise ProtocolError, "Claimed identifier #{claimed_id} is not a valid URI"
      end

      return @claimed_id if not parsed_identifier.fragment

      disp = parsed_identifier
      disp.fragment = nil

      return disp.to_s
    end

    def display_identifier=(display_identifier)
      @display_identifier = display_identifier
    end

    def uses_extension(extension_uri)
      return @type_uris.member?(extension_uri)
    end

    def preferred_namespace
      if (@type_uris.member?(OPENID_IDP_2_0_TYPE) or
          @type_uris.member?(OPENID_2_0_TYPE))
        return OPENID_2_0_MESSAGE_NS
      else
        return OPENID_1_0_MESSAGE_NS
      end
    end

    def supports_type(type_uri)
      # Does this endpoint support this type?
      #
      # I consider C{/server} endpoints to implicitly support C{/signon}.
      (
       @type_uris.member?(type_uri) or
       (type_uri == OPENID_2_0_TYPE and is_op_identifier())
       )
    end

    def compatibility_mode
      return preferred_namespace() != OPENID_2_0_MESSAGE_NS
    end

    def is_op_identifier
      return @type_uris.member?(OPENID_IDP_2_0_TYPE)
    end

    def parse_service(yadis_url, uri, type_uris, service_element)
      # Set the state of this object based on the contents of the
      # service element.
      @type_uris = type_uris
      @server_url = uri
      @used_yadis = true

      if !is_op_identifier()
        # XXX: This has crappy implications for Service elements that
        # contain both 'server' and 'signon' Types.  But that's a
        # pathological configuration anyway, so I don't think I care.
        @local_id = OpenID.find_op_local_identifier(service_element,
                                                    @type_uris)
        @claimed_id = yadis_url
      end
    end

    def get_local_id
      # Return the identifier that should be sent as the
      # openid.identity parameter to the server.
      if @local_id.nil? and @canonical_id.nil?
        return @claimed_id
      else
        return (@local_id or @canonical_id)
      end
    end

    def self.from_basic_service_endpoint(endpoint)
      # Create a new instance of this class from the endpoint object
      # passed in.
      #
      # @return: nil or OpenIDServiceEndpoint for this endpoint object"""

      type_uris = endpoint.match_types(OPENID_TYPE_URIS)

      # If any Type URIs match and there is an endpoint URI specified,
      # then this is an OpenID endpoint
      if (!type_uris.nil? and !type_uris.empty?) and !endpoint.uri.nil?
        openid_endpoint = self.new
        openid_endpoint.parse_service(
                                      endpoint.yadis_url,
                                      endpoint.uri,
                                      endpoint.type_uris,
                                      endpoint.service_element)
      else
        openid_endpoint = nil
      end

      return openid_endpoint
    end

    def self.from_html(uri, html)
      # Parse the given document as HTML looking for an OpenID <link
      # rel=...>
      #
      # @rtype: [OpenIDServiceEndpoint]

      discovery_types = [
                         [OPENID_2_0_TYPE, 'openid2.provider', 'openid2.local_id'],
                         [OPENID_1_1_TYPE, 'openid.server', 'openid.delegate'],
                        ]

      link_attrs = OpenID.parse_link_attrs(html)
      services = []
      discovery_types.each { |type_uri, op_endpoint_rel, local_id_rel|

        op_endpoint_url = OpenID.find_first_href(link_attrs, op_endpoint_rel)

        if !op_endpoint_url
          next
        end

        service = self.new
        service.claimed_id = uri
        service.local_id = OpenID.find_first_href(link_attrs, local_id_rel)
        service.server_url = op_endpoint_url
        service.type_uris = [type_uri]

        services << service
      }

      return services
    end

    def self.from_xrds(uri, xrds)
      # Parse the given document as XRDS looking for OpenID services.
      #
      # @rtype: [OpenIDServiceEndpoint]
      #
      # @raises L{XRDSError}: When the XRDS does not parse.
      return Yadis::apply_filter(uri, xrds, self)
    end

    def self.from_discovery_result(discoveryResult)
      # Create endpoints from a DiscoveryResult.
      #
      # @type discoveryResult: L{DiscoveryResult}
      #
      # @rtype: list of L{OpenIDServiceEndpoint}
      #
      # @raises L{XRDSError}: When the XRDS does not parse.
      if discoveryResult.is_xrds()
        meth = self.method('from_xrds')
      else
        meth = self.method('from_html')
      end

      return meth.call(discoveryResult.normalized_uri,
                       discoveryResult.response_text)
    end

    def self.from_op_endpoint_url(op_endpoint_url)
      # Construct an OP-Identifier OpenIDServiceEndpoint object for
      # a given OP Endpoint URL
      #
      # @param op_endpoint_url: The URL of the endpoint
      # @rtype: OpenIDServiceEndpoint
      service = self.new
      service.server_url = op_endpoint_url
      service.type_uris = [OPENID_IDP_2_0_TYPE]
      return service
    end

    def to_s
      return sprintf("<%s server_url=%s claimed_id=%s " +
                     "local_id=%s canonical_id=%s used_yadis=%s>",
                     self.class, @server_url, @claimed_id,
                     @local_id, @canonical_id, @used_yadis)
    end
  end

  def self.find_op_local_identifier(service_element, type_uris)
    # Find the OP-Local Identifier for this xrd:Service element.
    #
    # This considers openid:Delegate to be a synonym for xrd:LocalID
    # if both OpenID 1.X and OpenID 2.0 types are present. If only
    # OpenID 1.X is present, it returns the value of
    # openid:Delegate. If only OpenID 2.0 is present, it returns the
    # value of xrd:LocalID. If there is more than one LocalID tag and
    # the values are different, it raises a DiscoveryFailure. This is
    # also triggered when the xrd:LocalID and openid:Delegate tags are
    # different.

    # XXX: Test this function on its own!

    # Build the list of tags that could contain the OP-Local
    # Identifier
    local_id_tags = []
    if type_uris.member?(OPENID_1_1_TYPE) or
        type_uris.member?(OPENID_1_0_TYPE)
      # local_id_tags << Yadis::nsTag(OPENID_1_0_NS, 'openid', 'Delegate')
      service_element.add_namespace('openid', OPENID_1_0_NS)
      local_id_tags << "openid:Delegate"
    end

    if type_uris.member?(OPENID_2_0_TYPE)
      # local_id_tags.append(Yadis::nsTag(XRD_NS_2_0, 'xrd', 'LocalID'))
      service_element.add_namespace('xrd', Yadis::XRD_NS_2_0)
      local_id_tags << "xrd:LocalID"
    end

    # Walk through all the matching tags and make sure that they all
    # have the same value
    local_id = nil
    local_id_tags.each { |local_id_tag|
      service_element.each_element(local_id_tag) { |local_id_element|
        if local_id.nil?
          local_id = local_id_element.text
        elsif local_id != local_id_element.text
          format = 'More than one %s tag found in one service element'
          message = sprintf(format, local_id_tag)
          raise DiscoveryFailure.new(message, nil)
        end
      }
    }

    return local_id
  end

  def self.normalize_xri(xri)
    # Normalize an XRI, stripping its scheme if present
    m = /^xri:\/\/(.*)/.match(xri)
    xri = m[1] if m
    return xri
  end

  def self.normalize_url(url)
    # Normalize a URL, converting normalization failures to
    # DiscoveryFailure
    begin
      normalized = URINorm.urinorm(url)
    rescue URI::Error => why
      raise DiscoveryFailure.new("Error normalizing #{url}: #{why.message}", nil)
    else
      defragged = URI::parse(normalized)
      defragged.fragment = nil
      return defragged.normalize.to_s
    end
  end

  def self.best_matching_service(service, preferred_types)
    # Return the index of the first matching type, or something higher
    # if no type matches.
    #
    # This provides an ordering in which service elements that contain
    # a type that comes earlier in the preferred types list come
    # before service elements that come later. If a service element
    # has more than one type, the most preferred one wins.
    preferred_types.each_with_index { |value, index|
      if service.type_uris.member?(value)
        return index
      end
    }

    return preferred_types.length
  end

  def self.arrange_by_type(service_list, preferred_types)
    # Rearrange service_list in a new list so services are ordered by
    # types listed in preferred_types.  Return the new list.

    # Build a list with the service elements in tuples whose
    # comparison will prefer the one with the best matching service
    prio_services = []

    service_list.each_with_index { |s, index|
      prio_services << [best_matching_service(s, preferred_types), index, s]
    }

    prio_services.sort!

    # Now that the services are sorted by priority, remove the sort
    # keys from the list.
    (0...prio_services.length).each { |i|
      prio_services[i] = prio_services[i][2]
    }

    return prio_services
  end

  def self.get_op_or_user_services(openid_services)
    # Extract OP Identifier services.  If none found, return the rest,
    # sorted with most preferred first according to
    # OpenIDServiceEndpoint.openid_type_uris.
    #
    # openid_services is a list of OpenIDServiceEndpoint objects.
    #
    # Returns a list of OpenIDServiceEndpoint objects.

    op_services = arrange_by_type(openid_services, [OPENID_IDP_2_0_TYPE])

    openid_services = arrange_by_type(openid_services,
                                      OpenIDServiceEndpoint::OPENID_TYPE_URIS)

    if !op_services.empty?
      return op_services
    else
      return openid_services
    end
  end

  def self.discover_yadis(uri)
    # Discover OpenID services for a URI. Tries Yadis and falls back
    # on old-style <link rel='...'> discovery if Yadis fails.
    #
    # @param uri: normalized identity URL
    # @type uri: str
    # 
    # @return: (claimed_id, services)
    # @rtype: (str, list(OpenIDServiceEndpoint))
    #
    # @raises DiscoveryFailure: when discovery fails.

    # Might raise a yadis.discover.DiscoveryFailure if no document
    # came back for that URI at all.  I don't think falling back to
    # OpenID 1.0 discovery on the same URL will help, so don't bother
    # to catch it.
    response = Yadis.discover(uri)

    yadis_url = response.normalized_uri
    body = response.response_text

    begin
      openid_services = OpenIDServiceEndpoint.from_xrds(yadis_url, body)
    rescue Yadis::XRDSError
      # Does not parse as a Yadis XRDS file
      openid_services = []
    end

    if openid_services.empty?
      # Either not an XRDS or there are no OpenID services.

      if response.is_xrds
        # if we got the Yadis content-type or followed the Yadis
        # header, re-fetch the document without following the Yadis
        # header, with no Accept header.
        return self.discover_no_yadis(uri)
      end

      # Try to parse the response as HTML.
      # <link rel="...">
      openid_services = OpenIDServiceEndpoint.from_html(yadis_url, body)
    end

    return [yadis_url, self.get_op_or_user_services(openid_services)]
  end

  def self.discover_xri(iname)
    endpoints = []
    iname = self.normalize_xri(iname)

    begin
      canonical_id, services = Yadis::XRI::ProxyResolver.new().query(
            iname, OpenIDServiceEndpoint::OPENID_TYPE_URIS)

      if canonical_id.nil?
        raise Yadis::XRDSError.new(sprintf('No CanonicalID found for XRI %s', iname))
      end

      flt = Yadis.make_filter(OpenIDServiceEndpoint)

      services.each { |service_element|
        endpoints += flt.get_service_endpoints(iname, service_element)
      }
    rescue Yadis::XRDSError => why
      Util.log('xrds error on ' + iname + ': ' + why.to_s)
    end

    endpoints.each { |endpoint|
      # Is there a way to pass this through the filter to the endpoint
      # constructor instead of tacking it on after?
      endpoint.canonical_id = canonical_id
      endpoint.claimed_id = canonical_id
      endpoint.display_identifier = iname
    }

    # FIXME: returned xri should probably be in some normal form
    return [iname, self.get_op_or_user_services(endpoints)]
  end

  def self.discover_no_yadis(uri)
    http_resp = OpenID.fetch(uri)
    if http_resp.code != "200" and http_resp.code != "206"
      raise DiscoveryFailure.new(
        "HTTP Response status from identity URL host is not \"200\". "\
        "Got status #{http_resp.code.inspect}", http_resp)
    end

    claimed_id = http_resp.final_url
    openid_services = OpenIDServiceEndpoint.from_html(
        claimed_id, http_resp.body)
    return [claimed_id, openid_services]
  end

  def self.discover_uri(uri)
    # Hack to work around URI parsing for URls with *no* scheme.
    if uri.index("://").nil?
      uri = 'http://' + uri
    end

    begin
      parsed = URI::parse(uri)
    rescue URI::InvalidURIError => why
      raise DiscoveryFailure.new("URI is not valid: #{why.message}", nil)
    end

    if !parsed.scheme.nil? and !parsed.scheme.empty?
      if !['http', 'https'].member?(parsed.scheme)
        raise DiscoveryFailure.new(
                "URI scheme #{parsed.scheme} is not HTTP or HTTPS", nil)
      end
    end

    uri = self.normalize_url(uri)
    claimed_id, openid_services = self.discover_yadis(uri)
    claimed_id = self.normalize_url(claimed_id)
    return [claimed_id, openid_services]
  end

  def self.discover(identifier)
    if Yadis::XRI::identifier_scheme(identifier) == :xri
      normalized_identifier, services = discover_xri(identifier)
    else
      return discover_uri(identifier)
    end
  end
end
