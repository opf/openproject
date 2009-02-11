require 'openid/util'
require 'openid/kvform'

module OpenID

  IDENTIFIER_SELECT = 'http://specs.openid.net/auth/2.0/identifier_select'

  # URI for Simple Registration extension, the only commonly deployed
  # OpenID 1.x extension, and so a special case.
  SREG_URI = 'http://openid.net/sreg/1.0'

  # The OpenID 1.x namespace URIs
  OPENID1_NS = 'http://openid.net/signon/1.0'
  OPENID11_NS = 'http://openid.net/signon/1.1'
  OPENID1_NAMESPACES = [OPENID1_NS, OPENID11_NS]

  # The OpenID 2.0 namespace URI
  OPENID2_NS = 'http://specs.openid.net/auth/2.0'

  # The namespace consisting of pairs with keys that are prefixed with
  # "openid." but not in another namespace.
  NULL_NAMESPACE = :null_namespace

  # The null namespace, when it is an allowed OpenID namespace
  OPENID_NS = :openid_namespace

  # The top-level namespace, excluding all pairs with keys that start
  # with "openid."
  BARE_NS = :bare_namespace

  # Limit, in bytes, of identity provider and return_to URLs,
  # including response payload.  See OpenID 1.1 specification,
  # Appendix D.
  OPENID1_URL_LIMIT = 2047

  # All OpenID protocol fields.  Used to check namespace aliases.
  OPENID_PROTOCOL_FIELDS = [
                            'ns', 'mode', 'error', 'return_to',
                            'contact', 'reference', 'signed',
                            'assoc_type', 'session_type',
                            'dh_modulus', 'dh_gen',
                            'dh_consumer_public', 'claimed_id',
                            'identity', 'realm', 'invalidate_handle',
                            'op_endpoint', 'response_nonce', 'sig',
                            'assoc_handle', 'trust_root', 'openid',
                           ]

  # Sentinel used for Message implementation to indicate that getArg
  # should raise an exception instead of returning a default.
  NO_DEFAULT = :no_default

  # Raised if the generic OpenID namespace is accessed when there
  # is no OpenID namespace set for this message.
  class UndefinedOpenIDNamespace < Exception; end

  # Raised when an alias or namespace URI has already been registered.
  class NamespaceAliasRegistrationError < Exception; end

  # Raised if openid.ns is not a recognized value.
  # See Message class variable @@allowed_openid_namespaces
  class InvalidOpenIDNamespace < Exception; end

  class Message
    attr_reader :namespaces

    # Raised when key lookup fails
    class KeyNotFound < IndexError ; end

    # Namespace / alias registration map.  See
    # register_namespace_alias.
    @@registered_aliases = {}

    # Registers a (namespace URI, alias) mapping in a global namespace
    # alias map.  Raises NamespaceAliasRegistrationError if either the
    # namespace URI or alias has already been registered with a
    # different value.  This function is required if you want to use a
    # namespace with an OpenID 1 message.
    def Message.register_namespace_alias(namespace_uri, alias_)
      if @@registered_aliases[alias_] == namespace_uri
          return
      end

      if @@registered_aliases.values.include?(namespace_uri)
        raise NamespaceAliasRegistrationError,
          'Namespace uri #{namespace_uri} already registered'
      end

      if @@registered_aliases.member?(alias_)
        raise NamespaceAliasRegistrationError,
          'Alias #{alias_} already registered'
      end

      @@registered_aliases[alias_] = namespace_uri
    end

    @@allowed_openid_namespaces = [OPENID1_NS, OPENID2_NS, OPENID11_NS]

    # Raises InvalidNamespaceError if you try to instantiate a Message
    # with a namespace not in the above allowed list
    def initialize(openid_namespace=nil)
      @args = {}
      @namespaces = NamespaceMap.new
      if openid_namespace
        implicit = OPENID1_NAMESPACES.member? openid_namespace
        self.set_openid_namespace(openid_namespace, implicit)
      else
        @openid_ns_uri = nil
      end
    end

    # Construct a Message containing a set of POST arguments.
    # Raises InvalidNamespaceError if you try to instantiate a Message
    # with a namespace not in the above allowed list
    def Message.from_post_args(args)
      m = Message.new
      openid_args = {}
      args.each do |key,value|
        if value.is_a?(Array)
          raise ArgumentError, "Query dict must have one value for each key, " +
            "not lists of values.  Query is #{args.inspect}"
        end

        prefix, rest = key.split('.', 2)

        if prefix != 'openid' or rest.nil?
          m.set_arg(BARE_NS, key, value)
        else
          openid_args[rest] = value
        end
      end

      m._from_openid_args(openid_args)
      return m
    end

    # Construct a Message from a parsed KVForm message.
    # Raises InvalidNamespaceError if you try to instantiate a Message
    # with a namespace not in the above allowed list
    def Message.from_openid_args(openid_args)
      m = Message.new
      m._from_openid_args(openid_args)
      return m
    end

    # Raises InvalidNamespaceError if you try to instantiate a Message
    # with a namespace not in the above allowed list
    def _from_openid_args(openid_args)
      ns_args = []

      # resolve namespaces
      openid_args.each { |rest, value|
        ns_alias, ns_key = rest.split('.', 2)
        if ns_key.nil?
          ns_alias = NULL_NAMESPACE
          ns_key = rest
        end

        if ns_alias == 'ns'
          @namespaces.add_alias(value, ns_key)
        elsif ns_alias == NULL_NAMESPACE and ns_key == 'ns'
          set_openid_namespace(value, false)
        else
          ns_args << [ns_alias, ns_key, value]
        end
      }

      # implicitly set an OpenID 1 namespace
      unless get_openid_namespace
        set_openid_namespace(OPENID1_NS, true)
      end

      # put the pairs into the appropriate namespaces
      ns_args.each { |ns_alias, ns_key, value|
        ns_uri = @namespaces.get_namespace_uri(ns_alias)
        unless ns_uri
          ns_uri = _get_default_namespace(ns_alias)
          unless ns_uri
            ns_uri = get_openid_namespace
            ns_key = "#{ns_alias}.#{ns_key}"
          else
            @namespaces.add_alias(ns_uri, ns_alias, true)
          end
        end
        self.set_arg(ns_uri, ns_key, value)
      }
    end

    def _get_default_namespace(mystery_alias)
      # only try to map an alias to a default if it's an
      # OpenID 1.x namespace
      if is_openid1
        @@registered_aliases[mystery_alias]
      end
    end

    def set_openid_namespace(openid_ns_uri, implicit)
      if !@@allowed_openid_namespaces.include?(openid_ns_uri)
        raise InvalidOpenIDNamespace, "Invalid null namespace: #{openid_ns_uri}"
      end
      @namespaces.add_alias(openid_ns_uri, NULL_NAMESPACE, implicit)
      @openid_ns_uri = openid_ns_uri
    end

    def get_openid_namespace
      return @openid_ns_uri
    end

    def is_openid1
      return OPENID1_NAMESPACES.member?(@openid_ns_uri)
    end

    def is_openid2
      return @openid_ns_uri == OPENID2_NS
    end

    # Create a message from a KVForm string
    def Message.from_kvform(kvform_string)
      return Message.from_openid_args(Util.kv_to_dict(kvform_string))
    end

    def copy
      return Marshal.load(Marshal.dump(self))
    end

    # Return all arguments with "openid." in from of namespaced arguments.
    def to_post_args
      args = {}

      # add namespace defs to the output
      @namespaces.each { |ns_uri, ns_alias|
        if @namespaces.implicit?(ns_uri)
          next
        end
        if ns_alias == NULL_NAMESPACE
          ns_key = 'openid.ns'
        else
          ns_key = 'openid.ns.' + ns_alias
        end
        args[ns_key] = ns_uri
      }

      @args.each { |k, value|
        ns_uri, ns_key = k
        key = get_key(ns_uri, ns_key)
        args[key] = value
      }

      return args
    end

    # Return all namespaced arguments, failing if any non-namespaced arguments
    # exist.
    def to_args
      post_args = self.to_post_args
      kvargs = {}
      post_args.each { |k,v|
        if !k.starts_with?('openid.')
          raise ArgumentError, "This message can only be encoded as a POST, because it contains arguments that are not prefixed with 'openid.'"
        else
          kvargs[k[7..-1]] = v
        end
      }
      return kvargs
    end

    # Generate HTML form markup that contains the values in this
    # message, to be HTTP POSTed as x-www-form-urlencoded UTF-8.
    def to_form_markup(action_url, form_tag_attrs=nil, submit_text='Continue')
      form_tag_attr_map = {}

      if form_tag_attrs
        form_tag_attrs.each { |name, attr|
          form_tag_attr_map[name] = attr
        }
      end

      form_tag_attr_map['action'] = action_url
      form_tag_attr_map['method'] = 'post'
      form_tag_attr_map['accept-charset'] = 'UTF-8'
      form_tag_attr_map['enctype'] = 'application/x-www-form-urlencoded'

      markup = "<form "

      form_tag_attr_map.each { |k, v|
        markup += " #{k}=\"#{v}\""
      }

      markup += ">\n"

      to_post_args.each { |k,v|
        markup += "<input type='hidden' name='#{k}' value='#{v}' />\n"
      }
      markup += "<input type='submit' value='#{submit_text}' />\n"
      markup += "\n</form>"
      return markup
    end

    # Generate a GET URL with the paramters in this message attacked as
    # query parameters.
    def to_url(base_url)
      return Util.append_args(base_url, self.to_post_args)
    end

    # Generate a KVForm string that contains the parameters in this message.
    # This will fail is the message contains arguments outside of the
    # "openid." prefix.
    def to_kvform
      return Util.dict_to_kv(to_args)
    end

    # Generate an x-www-urlencoded string.
    def to_url_encoded
      args = to_post_args.map.sort
      return Util.urlencode(args)
    end

    # Convert an input value into the internally used values of this obejct.
    def _fix_ns(namespace)
      if namespace == OPENID_NS
        unless @openid_ns_uri
          raise UndefinedOpenIDNamespace, 'OpenID namespace not set'
        else
          namespace = @openid_ns_uri
        end
      end

      if namespace == BARE_NS
        return namespace
      end

      if !namespace.is_a?(String)
        raise ArgumentError, ("Namespace must be BARE_NS, OPENID_NS or "\
                              "a string. Got #{namespace.inspect}")
      end

      if namespace.index(':').nil?
        msg = ("OpenID 2.0 namespace identifiers SHOULD be URIs. "\
               "Got #{namespace.inspect}")
        Util.log(msg)

        if namespace == 'sreg'
          msg = "Using #{SREG_URI} instead of \"sreg\" as namespace"
          Util.log(msg)
          return SREG_URI
        end
      end

      return namespace
    end

    def has_key?(namespace, ns_key)
      namespace = _fix_ns(namespace)
      return @args.member?([namespace, ns_key])
    end

    # Get the key for a particular namespaced argument
    def get_key(namespace, ns_key)
      namespace = _fix_ns(namespace)
      return ns_key if namespace == BARE_NS

      ns_alias = @namespaces.get_alias(namespace)

      # no alias is defined, so no key can exist
      return nil if ns_alias.nil?

      if ns_alias == NULL_NAMESPACE
        tail = ns_key
      else
        tail = "#{ns_alias}.#{ns_key}"
      end

      return 'openid.' + tail
    end

    # Get a value for a namespaced key.
    def get_arg(namespace, key, default=nil)
      namespace = _fix_ns(namespace)
      @args.fetch([namespace, key]) {
        if default == NO_DEFAULT
          raise KeyNotFound, "<#{namespace}>#{key} not in this message"
        else
          default
        end
      }
    end

    # Get the arguments that are defined for this namespace URI.
    def get_args(namespace)
      namespace = _fix_ns(namespace)
      args = {}
      @args.each { |k,v|
        pair_ns, ns_key = k
        args[ns_key] = v if pair_ns == namespace
      }
      return args
    end

    # Set multiple key/value pairs in one call.
    def update_args(namespace, updates)
      namespace = _fix_ns(namespace)
      updates.each {|k,v| set_arg(namespace, k, v)}
    end

    # Set a single argument in this namespace
    def set_arg(namespace, key, value)
      namespace = _fix_ns(namespace)
      @args[[namespace, key].freeze] = value
      if namespace != BARE_NS
        @namespaces.add(namespace)
      end
    end

    # Remove a single argument from this namespace.
    def del_arg(namespace, key)
      namespace = _fix_ns(namespace)
      _key = [namespace, key]
      @args.delete(_key)
    end

    def ==(other)
      other.is_a?(self.class) && @args == other.instance_eval { @args }
    end

    def get_aliased_arg(aliased_key, default=nil)
      if aliased_key == 'ns'
        return get_openid_namespace()
      end

      ns_alias, key = aliased_key.split('.', 2)
      if ns_alias == 'ns'
        uri = @namespaces.get_namespace_uri(key)
        if uri.nil? and default == NO_DEFAULT
          raise KeyNotFound, "Namespace #{key} not defined when looking "\
                             "for #{aliased_key}"
        else
          return (uri.nil? ? default : uri)
        end
      end

      if key.nil?
        key = aliased_key
        ns = nil
      else
        ns = @namespaces.get_namespace_uri(ns_alias)
      end

      if ns.nil?
        key = aliased_key
        ns = get_openid_namespace
      end

      return get_arg(ns, key, default)
    end
  end


  # Maintains a bidirectional map between namespace URIs and aliases.
  class NamespaceMap

    def initialize
      @alias_to_namespace = {}
      @namespace_to_alias = {}
      @implicit_namespaces = []
    end

    def get_alias(namespace_uri)
      @namespace_to_alias[namespace_uri]
    end

    def get_namespace_uri(namespace_alias)
      @alias_to_namespace[namespace_alias]
    end

    # Add an alias from this namespace URI to the alias.
    def add_alias(namespace_uri, desired_alias, implicit=false)
      # Check that desired_alias is not an openid protocol field as
      # per the spec.
      Util.assert(!OPENID_PROTOCOL_FIELDS.include?(desired_alias),
             "#{desired_alias} is not an allowed namespace alias")

      # check that there is not a namespace already defined for the
      # desired alias
      current_namespace_uri = @alias_to_namespace.fetch(desired_alias, nil)
      if current_namespace_uri and current_namespace_uri != namespace_uri
        raise IndexError, "Cannot map #{namespace_uri} to alias #{desired_alias}. #{current_namespace_uri} is already mapped to alias #{desired_alias}"
      end

      # Check that desired_alias does not contain a period as per the
      # spec.
      if desired_alias.is_a?(String)
          Util.assert(desired_alias.index('.').nil?,
                 "#{desired_alias} must not contain a dot")
      end

      # check that there is not already a (different) alias for this
      # namespace URI.
      _alias = @namespace_to_alias[namespace_uri]
      if _alias and _alias != desired_alias
        raise IndexError, "Cannot map #{namespace_uri} to alias #{desired_alias}. It is already mapped to alias #{_alias}"
      end

      @alias_to_namespace[desired_alias] = namespace_uri
      @namespace_to_alias[namespace_uri] = desired_alias
      @implicit_namespaces << namespace_uri if implicit
      return desired_alias
    end

    # Add this namespace URI to the mapping, without caring what alias
    # it ends up with.
    def add(namespace_uri)
      # see if this namepace is already mapped to an alias
      _alias = @namespace_to_alias[namespace_uri]
      return _alias if _alias

      # Fall back to generating a numberical alias
      i = 0
      while true
        _alias = 'ext' + i.to_s
        begin
          add_alias(namespace_uri, _alias)
        rescue IndexError
          i += 1
        else
          return _alias
        end
      end

      raise StandardError, 'Unreachable'
    end

    def member?(namespace_uri)
      @namespace_to_alias.has_key?(namespace_uri)
    end

    def each
      @namespace_to_alias.each {|k,v| yield k,v}
    end

    def namespace_uris
      # Return an iterator over the namespace URIs
      return @namespace_to_alias.keys()
    end

    def implicit?(namespace_uri)
      return @implicit_namespaces.member?(namespace_uri)
    end

    def aliases
      # Return an iterator over the aliases
      return @alias_to_namespace.keys()
    end
  end
end
