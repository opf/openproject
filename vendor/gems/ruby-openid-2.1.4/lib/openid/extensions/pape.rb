# An implementation of the OpenID Provider Authentication Policy
# Extension 1.0
# see: http://openid.net/specs/

require 'openid/extension'

module OpenID

  module PAPE
    NS_URI = "http://specs.openid.net/extensions/pape/1.0"
    AUTH_MULTI_FACTOR_PHYSICAL =
      'http://schemas.openid.net/pape/policies/2007/06/multi-factor-physical'
    AUTH_MULTI_FACTOR =
      'http://schemas.openid.net/pape/policies/2007/06/multi-factor'
    AUTH_PHISHING_RESISTANT =
      'http://schemas.openid.net/pape/policies/2007/06/phishing-resistant'
    TIME_VALIDATOR = /\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\dZ/
    # A Provider Authentication Policy request, sent from a relying
    # party to a provider
    class Request < Extension
      attr_accessor :preferred_auth_policies, :max_auth_age, :ns_alias, :ns_uri
      def initialize(preferred_auth_policies=[], max_auth_age=nil)
        @ns_alias = 'pape'
        @ns_uri = NS_URI
        @preferred_auth_policies = preferred_auth_policies
        @max_auth_age = max_auth_age
      end

      # Add an acceptable authentication policy URI to this request
      # This method is intended to be used by the relying party to add
      # acceptable authentication types to the request.
      def add_policy_uri(policy_uri)
        unless @preferred_auth_policies.member? policy_uri
          @preferred_auth_policies << policy_uri
        end
      end

      def get_extension_args
        ns_args = {
          'preferred_auth_policies' => @preferred_auth_policies.join(' ')
        }
        ns_args['max_auth_age'] = @max_auth_age.to_s if @max_auth_age
        return ns_args
      end

      # Instantiate a Request object from the arguments in a
      # checkid_* OpenID message
      # return nil if the extension was not requested.
      def self.from_openid_request(oid_req)
        pape_req = new
        args = oid_req.message.get_args(NS_URI)
        if args == {}
          return nil
        end
        pape_req.parse_extension_args(args)
        return pape_req
      end

      # Set the state of this request to be that expressed in these
      # PAPE arguments
      def parse_extension_args(args)
        @preferred_auth_policies = []
        policies_str = args['preferred_auth_policies']
        if policies_str
          policies_str.split(' ').each{|uri|
            add_policy_uri(uri)
          }
        end

        max_auth_age_str = args['max_auth_age']
        if max_auth_age_str
          @max_auth_age = max_auth_age_str.to_i
        else
          @max_auth_age = nil
        end
      end

      # Given a list of authentication policy URIs that a provider
      # supports, this method returns the subset of those types
      # that are preferred by the relying party.
      def preferred_types(supported_types)
        @preferred_auth_policies.select{|uri| supported_types.member? uri}
      end
    end

    # A Provider Authentication Policy response, sent from a provider
    # to a relying party
    class Response < Extension
      attr_accessor :ns_alias, :auth_policies, :auth_time, :nist_auth_level
      def initialize(auth_policies=[], auth_time=nil, nist_auth_level=nil)
        @ns_alias = 'pape'
        @ns_uri = NS_URI
        @auth_policies = auth_policies
        @auth_time = auth_time
        @nist_auth_level = nist_auth_level
      end

      # Add a policy URI to the response
      # see http://openid.net/specs/openid-provider-authentication-policy-extension-1_0-01.html#auth_policies
      def add_policy_uri(policy_uri)
        @auth_policies << policy_uri unless @auth_policies.member?(policy_uri)
      end

      # Create a Response object from an OpenID::Consumer::SuccessResponse
      def self.from_success_response(success_response)
        args = success_response.get_signed_ns(NS_URI)
        return nil if args.nil?
        pape_resp = new
        pape_resp.parse_extension_args(args)
        return pape_resp
      end

      # parse the provider authentication policy arguments into the
      # internal state of this object
      # if strict is specified, raise an exception when bad data is
      # encountered
      def parse_extension_args(args, strict=false)
        policies_str = args['auth_policies']
        if policies_str and policies_str != 'none'
          @auth_policies = policies_str.split(' ')
        end

        nist_level_str = args['nist_auth_level']
        if nist_level_str
          # special handling of zero to handle to_i behavior
          if nist_level_str.strip == '0'
            nist_level = 0
          else
            nist_level = nist_level_str.to_i
            # if it's zero here we have a bad value
            if nist_level == 0
              nist_level = nil
            end
          end
          if nist_level and nist_level >= 0 and nist_level < 5
            @nist_auth_level = nist_level
          elsif strict
            raise ArgumentError, "nist_auth_level must be an integer 0 through 4, not #{nist_level_str.inspect}"
          end
        end

        auth_time_str = args['auth_time']
        if auth_time_str
          # validate time string
          if auth_time_str =~ TIME_VALIDATOR
            @auth_time = auth_time_str
          elsif strict
            raise ArgumentError, "auth_time must be in RFC3339 format"
          end
        end
      end

      def get_extension_args
        ns_args = {}
        if @auth_policies.empty?
          ns_args['auth_policies'] = 'none'
        else
          ns_args['auth_policies'] = @auth_policies.join(' ')
        end
        if @nist_auth_level
          unless (0..4).member? @nist_auth_level
            raise ArgumentError, "nist_auth_level must be an integer 0 through 4, not #{@nist_auth_level.inspect}"
          end
          ns_args['nist_auth_level'] = @nist_auth_level.to_s
        end

        if @auth_time
          unless @auth_time =~ TIME_VALIDATOR
            raise ArgumentError, "auth_time must be in RFC3339 format"
          end
          ns_args['auth_time'] = @auth_time
        end
        return ns_args
      end

    end
  end

end
