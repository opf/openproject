require 'openid/extension'
require 'openid/util'
require 'openid/message'

module OpenID
  module SReg
    DATA_FIELDS = {
      'fullname'=>'Full Name',
      'nickname'=>'Nickname',
      'dob'=>'Date of Birth',
      'email'=>'E-mail Address',
      'gender'=>'Gender',
      'postcode'=>'Postal Code',
      'country'=>'Country',
      'language'=>'Language',
      'timezone'=>'Time Zone',
    }

    NS_URI_1_0 = 'http://openid.net/sreg/1.0'
    NS_URI_1_1 = 'http://openid.net/extensions/sreg/1.1'
    NS_URI = NS_URI_1_1

    begin
      Message.register_namespace_alias(NS_URI_1_1, 'sreg')
    rescue NamespaceAliasRegistrationError => e
      Util.log(e)
    end

    # raise ArgumentError if fieldname is not in the defined sreg fields
    def OpenID.check_sreg_field_name(fieldname)
      unless DATA_FIELDS.member? fieldname
        raise ArgumentError, "#{fieldname} is not a defined simple registration field"
      end
    end

    # Does the given endpoint advertise support for simple registration?
    def OpenID.supports_sreg?(endpoint)
      endpoint.uses_extension(NS_URI_1_1) || endpoint.uses_extension(NS_URI_1_0)
    end

    # Extract the simple registration namespace URI from the given
    # OpenID message. Handles OpenID 1 and 2, as well as both sreg
    # namespace URIs found in the wild, as well as missing namespace
    # definitions (for OpenID 1)
    def OpenID.get_sreg_ns(message)
      [NS_URI_1_1, NS_URI_1_0].each{|ns|
        if message.namespaces.get_alias(ns)
          return ns
        end
      }
      # try to add an alias, since we didn't find one
      ns = NS_URI_1_1
      begin
        message.namespaces.add_alias(ns, 'sreg')
      rescue IndexError
        raise NamespaceError
      end
      return ns
    end

    # The simple registration namespace was not found and could not
    # be created using the expected name (there's another extension
    # using the name 'sreg')
    #
    # This is not <em>illegal</em>, for OpenID 2, although it probably
    # indicates a problem, since it's not expected that other extensions
    # will re-use the alias that is in use for OpenID 1.
    #
    # If this is an OpenID 1 request, then there is no recourse. This
    # should not happen unless some code has modified the namespaces for
    # the message that is being processed.
    class NamespaceError < ArgumentError
    end

    # An object to hold the state of a simple registration request.
    class Request < Extension
      attr_reader :optional, :required, :ns_uri
      attr_accessor :policy_url
      def initialize(required = nil, optional = nil, policy_url = nil, ns_uri = NS_URI)
        super()

        @policy_url = policy_url
        @ns_uri = ns_uri
        @ns_alias = 'sreg'
        @required = []
        @optional = []

        if required
          request_fields(required, true, true)
        end
        if optional
          request_fields(optional, false, true)
        end
      end

      # Create a simple registration request that contains the
      # fields that were requested in the OpenID request with the
      # given arguments
      # Takes an OpenID::CheckIDRequest, returns an OpenID::Sreg::Request
      # return nil if the extension was not requested.
      def self.from_openid_request(request)
        # Since we're going to mess with namespace URI mapping, don't
        # mutate the object that was passed in.
        message = request.message.copy
        ns_uri = OpenID::get_sreg_ns(message)
        args = message.get_args(ns_uri)
        return nil if args == {}
        req = new(nil,nil,nil,ns_uri)
        req.parse_extension_args(args)
        return req
      end

      # Parse the unqualified simple registration request
      # parameters and add them to this object.
      #
      # This method is essentially the inverse of
      # getExtensionArgs. This method restores the serialized simple
      # registration request fields.
      #
      # If you are extracting arguments from a standard OpenID
      # checkid_* request, you probably want to use fromOpenIDRequest,
      # which will extract the sreg namespace and arguments from the
      # OpenID request. This method is intended for cases where the
      # OpenID server needs more control over how the arguments are
      # parsed than that method provides.
      def parse_extension_args(args, strict = false)
        required_items = args['required']
        unless required_items.nil? or required_items.empty?
          required_items.split(',').each{|field_name|
            begin
              request_field(field_name, true, strict)
            rescue ArgumentError
              raise if strict
            end
          }
        end

        optional_items = args['optional']
        unless optional_items.nil? or optional_items.empty?
          optional_items.split(',').each{|field_name|
            begin
              request_field(field_name, false, strict)
            rescue ArgumentError
              raise if strict
            end
          }
        end
        @policy_url = args['policy_url']
      end

      # A list of all of the simple registration fields that were
      # requested, whether they were required or optional.
      def all_requested_fields
        @required + @optional
      end

      # Have any simple registration fields been requested?
      def were_fields_requested?
        !all_requested_fields.empty?
      end

      # Request the specified field from the OpenID user
      # field_name: the unqualified simple registration field name
      # required: whether the given field should be presented
      #        to the user as being a required to successfully complete
      #        the request
      # strict: whether to raise an exception when a field is
      #        added to a request more than once
      # Raises ArgumentError if the field_name is not a simple registration
      # field, or if strict is set and a field is added more than once
      def request_field(field_name, required=false, strict=false)
        OpenID::check_sreg_field_name(field_name)

        if strict
          if (@required + @optional).member? field_name
            raise ArgumentError, 'That field has already been requested'
          end
        else
          return if @required.member? field_name
          if @optional.member? field_name
            if required
              @optional.delete field_name
            else
              return
            end
          end
        end
        if required
          @required << field_name
        else
          @optional << field_name
        end
      end

      # Add the given list of fields to the request.
      def request_fields(field_names, required = false, strict = false)
        raise ArgumentError unless field_names.respond_to?(:each) and
                                   field_names[0].is_a?(String)
        field_names.each{|fn|request_field(fn, required, strict)}
      end

      # Get a hash of unqualified simple registration arguments
      # representing this request.
      # This method is essentially the inverse of parse_extension_args.
      # This method serializes the simple registration request fields.
      def get_extension_args
        args = {}
        args['required'] = @required.join(',') unless @required.empty?
        args['optional'] = @optional.join(',') unless @optional.empty?
        args['policy_url'] = @policy_url unless @policy_url.nil?
        return args
      end

      def member?(field_name)
        all_requested_fields.member?(field_name)
      end

    end

    # Represents the data returned in a simple registration response
    # inside of an OpenID id_res response. This object will be
    # created by the OpenID server, added to the id_res response
    # object, and then extracted from the id_res message by the Consumer.
    class Response < Extension
      attr_reader :ns_uri, :data

      def initialize(data = {}, ns_uri=NS_URI)
        @ns_alias = 'sreg'
        @data = data
        @ns_uri = ns_uri
      end

      # Take a Request and a hash of simple registration
      # values and create a Response object containing that data.
      def self.extract_response(request, data)
        arf = request.all_requested_fields
        resp_data = data.reject{|k,v| !arf.member?(k) || v.nil? }
        new(resp_data, request.ns_uri)
      end

      # Create an Response object from an
      # OpenID::Consumer::SuccessResponse from consumer.complete
      # If you set the signed_only parameter to false, unsigned data from
      # the id_res message from the server will be processed.
      def self.from_success_response(success_response, signed_only = true)
        ns_uri = OpenID::get_sreg_ns(success_response.message)
        if signed_only
          args = success_response.get_signed_ns(ns_uri)
          return nil if args.nil? # No signed args, so fail
        else
          args = success_response.message.get_args(ns_uri)
        end
        args.reject!{|k,v| !DATA_FIELDS.member?(k) }
        new(args, ns_uri)
      end

      # Get the fields to put in the simple registration namespace
      # when adding them to an id_res message.
      def get_extension_args
        return @data
      end

      # Read-only hashlike interface.
      # Raises an exception if the field name is bad
      def [](field_name)
        OpenID::check_sreg_field_name(field_name)
        data[field_name]
      end

      def empty?
        @data.empty?
      end
      # XXX is there more to a hashlike interface I should add?
    end
  end
end

