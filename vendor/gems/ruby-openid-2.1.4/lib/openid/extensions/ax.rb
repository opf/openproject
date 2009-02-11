# Implements the OpenID attribute exchange specification, version 1.0

require 'openid/extension'
require 'openid/trustroot'
require 'openid/message'

module OpenID
  module AX

    UNLIMITED_VALUES = "unlimited"
    MINIMUM_SUPPORTED_ALIAS_LENGTH = 32

    # check alias for invalid characters, raise AXError if found
    def self.check_alias(name)
      if name.match(/(,|\.)/)
        raise Error, ("Alias #{name.inspect} must not contain a "\
                      "comma or period.")
      end
    end

    # Raised when data does not comply with AX 1.0 specification
    class Error < ArgumentError
    end

    # Abstract class containing common code for attribute exchange messages
    class AXMessage < Extension
      attr_accessor :ns_alias, :mode, :ns_uri

      NS_URI = 'http://openid.net/srv/ax/1.0'
      def initialize
        @ns_alias = 'ax'
        @ns_uri = NS_URI
        @mode = nil
      end

      protected

      # Raise an exception if the mode in the attribute exchange
      # arguments does not match what is expected for this class.
      def check_mode(ax_args)
        actual_mode = ax_args['mode']
        if actual_mode != @mode
          raise Error, "Expected mode #{mode.inspect}, got #{actual_mode.inspect}"
        end
      end

      def new_args
        {'mode' => @mode}
      end
    end

    # Represents a single attribute in an attribute exchange
    # request. This should be added to an Request object in order to
    # request the attribute.
    #
    # @ivar required: Whether the attribute will be marked as required
    #     when presented to the subject of the attribute exchange
    #     request.
    # @type required: bool
    #
    # @ivar count: How many values of this type to request from the
    #      subject. Defaults to one.
    # @type count: int
    #
    # @ivar type_uri: The identifier that determines what the attribute
    #      represents and how it is serialized. For example, one type URI
    #      representing dates could represent a Unix timestamp in base 10
    #      and another could represent a human-readable string.
    # @type type_uri: str
    #
    # @ivar ns_alias: The name that should be given to this alias in the
    #      request. If it is not supplied, a generic name will be
    #      assigned. For example, if you want to call a Unix timestamp
    #      value 'tstamp', set its alias to that value. If two attributes
    #      in the same message request to use the same alias, the request
    #      will fail to be generated.
    # @type alias: str or NoneType
    class AttrInfo < Object
      attr_reader :type_uri, :count, :ns_alias
      attr_accessor :required
      def initialize(type_uri, ns_alias=nil, required=false, count=1)
        @type_uri = type_uri
        @count = count
        @required = required
        @ns_alias = ns_alias
      end

      def wants_unlimited_values?
        @count == UNLIMITED_VALUES
      end
    end

    # Given a namespace mapping and a string containing a
    # comma-separated list of namespace aliases, return a list of type
    # URIs that correspond to those aliases.
    # namespace_map: OpenID::NamespaceMap
    def self.to_type_uris(namespace_map, alias_list_s)
      return [] if alias_list_s.nil?
      alias_list_s.split(',').inject([]) {|uris, name|
        type_uri = namespace_map.get_namespace_uri(name)
        raise IndexError, "No type defined for attribute name #{name.inspect}" if type_uri.nil?
        uris << type_uri
      }
    end


    # An attribute exchange 'fetch_request' message. This message is
    # sent by a relying party when it wishes to obtain attributes about
    # the subject of an OpenID authentication request.
    class FetchRequest < AXMessage
      attr_reader :requested_attributes
      attr_accessor :update_url

      def initialize(update_url = nil)
        super()
        @mode = 'fetch_request'
        @requested_attributes = {}
        @update_url = update_url
      end

      # Add an attribute to this attribute exchange request.
      # attribute: AttrInfo, the attribute being requested
      # Raises IndexError if the requested attribute is already present
      #   in this request.
      def add(attribute)
        if @requested_attributes[attribute.type_uri]
          raise IndexError, "The attribute #{attribute.type_uri} has already been requested"
        end
        @requested_attributes[attribute.type_uri] = attribute
      end

      # Get the serialized form of this attribute fetch request.
      # returns a hash of the arguments
      def get_extension_args
        aliases = NamespaceMap.new
        required = []
        if_available = []
        ax_args = new_args 
        @requested_attributes.each{|type_uri, attribute|
          if attribute.ns_alias
            name = aliases.add_alias(type_uri, attribute.ns_alias)
          else
            name = aliases.add(type_uri)
          end
          if attribute.required
            required << name
          else
            if_available << name
          end
          if attribute.count != 1
            ax_args["count.#{name}"] = attribute.count.to_s
          end
          ax_args["type.#{name}"] = type_uri
        }

        unless required.empty?
          ax_args['required'] = required.join(',')
        end
        unless if_available.empty?
          ax_args['if_available'] = if_available.join(',')
        end
        return ax_args
      end

      # Get the type URIs for all attributes that have been marked
      # as required.
      def get_required_attrs
        @requested_attributes.inject([]) {|required, (type_uri, attribute)|
          if attribute.required
            required << type_uri
          else
            required
          end
        }
      end

      # Extract a FetchRequest from an OpenID message
      # message: OpenID::Message
      # return a FetchRequest or nil if AX arguments are not present
      def self.from_openid_request(oidreq)
        message = oidreq.message
        ax_args = message.get_args(NS_URI)
        return nil if ax_args == {}
        req = new
        req.parse_extension_args(ax_args)

        if req.update_url
          realm = message.get_arg(OPENID_NS, 'realm',
                                  message.get_arg(OPENID_NS, 'return_to'))
          if realm.nil? or realm.empty?
            raise Error, "Cannot validate update_url #{req.update_url.inspect} against absent realm"
          end
          tr = TrustRoot::TrustRoot.parse(realm)
          unless tr.validate_url(req.update_url)
            raise Error, "Update URL #{req.update_url.inspect} failed validation against realm #{realm.inspect}"
          end
        end

        return req
      end

      def parse_extension_args(ax_args)
        check_mode(ax_args)

        aliases = NamespaceMap.new

        ax_args.each{|k,v|
          if k.index('type.') == 0
            name = k[5..-1]
            type_uri = v
            aliases.add_alias(type_uri, name)

            count_key = 'count.'+name
            count_s = ax_args[count_key]
            count = 1
            if count_s
              if count_s == UNLIMITED_VALUES
                count = count_s
              else
                count = count_s.to_i
                if count <= 0
                  raise Error, "Invalid value for count #{count_key.inspect}: #{count_s.inspect}"
                end
              end
            end
            add(AttrInfo.new(type_uri, name, false, count))
          end
        }

        required = AX.to_type_uris(aliases, ax_args['required'])
        required.each{|type_uri|
          @requested_attributes[type_uri].required = true
        }
        if_available = AX.to_type_uris(aliases, ax_args['if_available'])
        all_type_uris = required + if_available

        aliases.namespace_uris.each{|type_uri|
          unless all_type_uris.member? type_uri
            raise Error, "Type URI #{type_uri.inspect} was in the request but not present in 'required' or 'if_available'"
          end
        }
        @update_url = ax_args['update_url']
      end

      # return the list of AttrInfo objects contained in the FetchRequest
      def attributes
        @requested_attributes.values
      end

      # return the list of requested attribute type URIs
      def requested_types
        @requested_attributes.keys
      end

      def member?(type_uri)
        ! @requested_attributes[type_uri].nil?
      end

    end

    # Abstract class that implements a message that has attribute
    # keys and values. It contains the common code between
    # fetch_response and store_request.
    class KeyValueMessage < AXMessage
      attr_reader :data
      def initialize
        super()
        @mode = nil
        @data = {}
        @data.default = []
      end

      # Add a single value for the given attribute type to the
      # message. If there are already values specified for this type,
      # this value will be sent in addition to the values already
      # specified.
      def add_value(type_uri, value)
        @data[type_uri] = @data[type_uri] << value
      end

      # Set the values for the given attribute type. This replaces
      # any values that have already been set for this attribute.
      def set_values(type_uri, values)
        @data[type_uri] = values
      end

      # Get the extension arguments for the key/value pairs
      # contained in this message.
      def _get_extension_kv_args(aliases = nil)
        aliases = NamespaceMap.new if aliases.nil?

        ax_args = new_args

        @data.each{|type_uri, values|
          name = aliases.add(type_uri)
          ax_args['type.'+name] = type_uri
          ax_args['count.'+name] = values.size.to_s

          values.each_with_index{|value, i|
            key = "value.#{name}.#{i+1}"
            ax_args[key] = value
          }
        }
        return ax_args
      end

      # Parse attribute exchange key/value arguments into this object.

      def parse_extension_args(ax_args)
        check_mode(ax_args)
        aliases = NamespaceMap.new

        ax_args.each{|k, v|
          if k.index('type.') == 0
            type_uri = v
            name = k[5..-1]

            AX.check_alias(name)
            aliases.add_alias(type_uri,name)
          end
        }

        aliases.each{|type_uri, name|
          count_s = ax_args['count.'+name]
          count = count_s.to_i
          if count_s.nil?
            value = ax_args['value.'+name]
            if value.nil?
              raise IndexError, "Missing #{'value.'+name} in FetchResponse" 
            elsif value.empty?
              values = []
            else
              values = [value]
            end
          elsif count_s.to_i == 0
            values = []
          else
            values = (1..count).inject([]){|l,i|
              key = "value.#{name}.#{i}"
              v = ax_args[key]
              raise IndexError, "Missing #{key} in FetchResponse" if v.nil?
              l << v
            }
          end
          @data[type_uri] = values
        }
      end

      # Get a single value for an attribute. If no value was sent
      # for this attribute, use the supplied default. If there is more
      # than one value for this attribute, this method will fail.
      def get_single(type_uri, default = nil)
        values = @data[type_uri]
        return default if values.empty?
        if values.size != 1
          raise Error, "More than one value present for #{type_uri.inspect}"
        else
          return values[0]
        end
      end

      # retrieve the list of values for this attribute
      def get(type_uri)
        @data[type_uri]
      end
      
      # retrieve the list of values for this attribute
      def [](type_uri)
        @data[type_uri]
      end

      # get the number of responses for this attribute
      def count(type_uri)
        @data[type_uri].size
      end

    end

    # A fetch_response attribute exchange message
    class FetchResponse < KeyValueMessage
      attr_reader :update_url

      def initialize(update_url = nil)
        super()
        @mode = 'fetch_response'
        @update_url = update_url
      end

      # Serialize this object into arguments in the attribute
      # exchange namespace
      # Takes an optional FetchRequest.  If specified, the response will be
      # validated against this request, and empty responses for requested
      # fields with no data will be sent.
      def get_extension_args(request = nil)
        aliases = NamespaceMap.new
        zero_value_types = []

        if request
          # Validate the data in the context of the request (the
          # same attributes should be present in each, and the
          # counts in the response must be no more than the counts
          # in the request)
          @data.keys.each{|type_uri|
            unless request.member? type_uri
              raise IndexError, "Response attribute not present in request: #{type_uri.inspect}"
            end
          }

          request.attributes.each{|attr_info|
            # Copy the aliases from the request so that reading
            # the response in light of the request is easier
            if attr_info.ns_alias.nil?
              aliases.add(attr_info.type_uri)
            else
              aliases.add_alias(attr_info.type_uri, attr_info.ns_alias)
            end
            values = @data[attr_info.type_uri]
            if values.empty? # @data defaults to []
              zero_value_types << attr_info
            end
            if attr_info.count != UNLIMITED_VALUES and attr_info.count < values.size
              raise Error, "More than the number of requested values were specified for #{attr_info.type_uri.inspect}"
            end
          }
        end

        kv_args = _get_extension_kv_args(aliases)

        # Add the KV args into the response with the args that are
        # unique to the fetch_response
        ax_args = new_args

        zero_value_types.each{|attr_info|
          name = aliases.get_alias(attr_info.type_uri)
          kv_args['type.' + name] = attr_info.type_uri
          kv_args['count.' + name] = '0'
        }
        update_url = (request and request.update_url or @update_url)
        ax_args['update_url'] = update_url unless update_url.nil?
        ax_args.update(kv_args)
        return ax_args
      end

      def parse_extension_args(ax_args)
        super
        @update_url = ax_args['update_url']
      end

      # Construct a FetchResponse object from an OpenID library
      # SuccessResponse object.
      def self.from_success_response(success_response, signed=true)
        obj = self.new
        if signed
          ax_args = success_response.get_signed_ns(obj.ns_uri)
        else
          ax_args = success_response.message.get_args(obj.ns_uri)
        end

        begin
          obj.parse_extension_args(ax_args)
          return obj
        rescue Error => e
          return nil
        end
      end
    end

    # A store request attribute exchange message representation
    class StoreRequest < KeyValueMessage
      def initialize
        super
        @mode = 'store_request'
      end

      def get_extension_args(aliases=nil)
        ax_args = new_args
        kv_args = _get_extension_kv_args(aliases)
        ax_args.update(kv_args)
        return ax_args
      end
    end

    # An indication that the store request was processed along with
    # this OpenID transaction.
    class StoreResponse < AXMessage
      SUCCESS_MODE = 'store_response_success'
      FAILURE_MODE = 'store_response_failure'
      attr_reader :error_message

      def initialize(succeeded = true, error_message = nil)
        super()
        if succeeded and error_message
          raise Error, "Error message included in a success response"
        end
        if succeeded
          @mode = SUCCESS_MODE
        else
          @mode = FAILURE_MODE
        end
        @error_message = error_message
      end

      def succeeded?
        @mode == SUCCESS_MODE
      end

      def get_extension_args
        ax_args = new_args
        if !succeeded? and error_message
          ax_args['error'] = @error_message
        end
        return ax_args
      end
    end
  end
end
