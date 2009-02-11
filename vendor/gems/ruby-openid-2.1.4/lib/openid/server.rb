
require 'openid/cryptutil'
require 'openid/util'
require 'openid/dh'
require 'openid/store/nonce'
require 'openid/trustroot'
require 'openid/association'
require 'openid/message'

require 'time'

module OpenID

  module Server

    HTTP_OK = 200
    HTTP_REDIRECT = 302
    HTTP_ERROR = 400

    BROWSER_REQUEST_MODES = ['checkid_setup', 'checkid_immediate']

    ENCODE_KVFORM = ['kvform'].freeze
    ENCODE_URL = ['URL/redirect'].freeze
    ENCODE_HTML_FORM = ['HTML form'].freeze

    UNUSED = nil

    class OpenIDRequest
      attr_accessor :message, :mode

      # I represent an incoming OpenID request.
      #
      # Attributes:
      # mode:: The "openid.mode" of this request
      def initialize
        @mode = nil
        @message = nil
      end

      def namespace
        if @message.nil?
          raise RuntimeError, "Request has no message"
        else
          return @message.get_openid_namespace
        end
      end
    end

    # A request to verify the validity of a previous response.
    #
    # See OpenID Specs, Verifying Directly with the OpenID Provider
    # <http://openid.net/specs/openid-authentication-2_0-12.html#verifying_signatures>
    class CheckAuthRequest < OpenIDRequest

      # The association handle the response was signed with.
      attr_accessor :assoc_handle

      # The message with the signature which wants checking.
      attr_accessor :signed

      # An association handle the client is asking about the validity
      # of. May be nil.
      attr_accessor :invalidate_handle

      attr_accessor :sig

      # Construct me.
      #
      # These parameters are assigned directly as class attributes.
      #
      # Parameters:
      # assoc_handle:: the association handle for this request
      # signed:: The signed message
      # invalidate_handle:: An association handle that the relying
      #                     party is checking to see if it is invalid
      def initialize(assoc_handle, signed, invalidate_handle=nil)
        super()

        @mode = "check_authentication"
        @required_fields = ["identity", "return_to", "response_nonce"].freeze

        @sig = nil
        @assoc_handle = assoc_handle
        @signed = signed
        @invalidate_handle = invalidate_handle
      end

      # Construct me from an OpenID::Message.
      def self.from_message(message, op_endpoint=UNUSED)
        assoc_handle = message.get_arg(OPENID_NS, 'assoc_handle')
        invalidate_handle = message.get_arg(OPENID_NS, 'invalidate_handle')

        signed = message.copy()
        # openid.mode is currently check_authentication because
        # that's the mode of this request.  But the signature
        # was made on something with a different openid.mode.
        # http://article.gmane.org/gmane.comp.web.openid.general/537
        if signed.has_key?(OPENID_NS, "mode")
          signed.set_arg(OPENID_NS, "mode", "id_res")
        end

        obj = self.new(assoc_handle, signed, invalidate_handle)
        obj.message = message
        obj.sig = message.get_arg(OPENID_NS, 'sig')

        if !obj.assoc_handle or
            !obj.sig
          msg = sprintf("%s request missing required parameter from message %s",
                        obj.mode, message)
            raise ProtocolError.new(message, msg)
        end

        return obj
      end

      # Respond to this request.
      #
      # Given a Signatory, I can check the validity of the signature
      # and the invalidate_handle.  I return a response with an
      # is_valid (and, if appropriate invalidate_handle) field.
      def answer(signatory)
        is_valid = signatory.verify(@assoc_handle, @signed)
        # Now invalidate that assoc_handle so it this checkAuth
        # message cannot be replayed.
        signatory.invalidate(@assoc_handle, dumb=true)
        response = OpenIDResponse.new(self)
        valid_str = is_valid ? "true" : "false"
        response.fields.set_arg(OPENID_NS, 'is_valid', valid_str)

        if @invalidate_handle
          assoc = signatory.get_association(@invalidate_handle, false)
          if !assoc
            response.fields.set_arg(
                    OPENID_NS, 'invalidate_handle', @invalidate_handle)
          end
        end

        return response
      end

      def to_s
        ih = nil

        if @invalidate_handle
          ih = sprintf(" invalidate? %s", @invalidate_handle)
        else
          ih = ""
        end

        s = sprintf("<%s handle: %s sig: %s: signed: %s%s>",
                    self.class, @assoc_handle,
                    @sig, @signed, ih)
        return s
      end
    end

    class BaseServerSession
      attr_reader :session_type

      def initialize(session_type, allowed_assoc_types)
        @session_type = session_type
        @allowed_assoc_types = allowed_assoc_types.dup.freeze
      end

      def allowed_assoc_type?(typ)
        @allowed_assoc_types.member?(typ)
      end
    end

    # An object that knows how to handle association requests with
    # no session type.
    #
    # See OpenID Specs, Section 8: Establishing Associations
    # <http://openid.net/specs/openid-authentication-2_0-12.html#associations>
    class PlainTextServerSession < BaseServerSession
      # The session_type for this association session. There is no
      # type defined for plain-text in the OpenID specification, so we
      # use 'no-encryption'.
      attr_reader :session_type

      def initialize
        super('no-encryption', ['HMAC-SHA1', 'HMAC-SHA256'])
      end

      def self.from_message(unused_request)
        return self.new
      end

      def answer(secret)
        return {'mac_key' => Util.to_base64(secret)}
      end
    end

    # An object that knows how to handle association requests with the
    # Diffie-Hellman session type.
    #
    # See OpenID Specs, Section 8: Establishing Associations
    # <http://openid.net/specs/openid-authentication-2_0-12.html#associations>
    class DiffieHellmanSHA1ServerSession < BaseServerSession

      # The Diffie-Hellman algorithm values for this request
      attr_accessor :dh

      # The public key sent by the consumer in the associate request
      attr_accessor :consumer_pubkey

      # The session_type for this association session.
      attr_reader :session_type

      def initialize(dh, consumer_pubkey)
        super('DH-SHA1', ['HMAC-SHA1'])

        @hash_func = CryptUtil.method('sha1')
        @dh = dh
        @consumer_pubkey = consumer_pubkey
      end

      # Construct me from OpenID Message
      #
      # Raises ProtocolError when parameters required to establish the
      # session are missing.
      def self.from_message(message)
        dh_modulus = message.get_arg(OPENID_NS, 'dh_modulus')
        dh_gen = message.get_arg(OPENID_NS, 'dh_gen')
        if ((!dh_modulus and dh_gen) or
            (!dh_gen and dh_modulus))

          if !dh_modulus
            missing = 'modulus'
          else
            missing = 'generator'
          end

          raise ProtocolError.new(message,
                  sprintf('If non-default modulus or generator is ' +
                          'supplied, both must be supplied. Missing %s',
                          missing))
        end

        if dh_modulus or dh_gen
          dh_modulus = CryptUtil.base64_to_num(dh_modulus)
          dh_gen = CryptUtil.base64_to_num(dh_gen)
          dh = DiffieHellman.new(dh_modulus, dh_gen)
        else
          dh = DiffieHellman.from_defaults()
        end

        consumer_pubkey = message.get_arg(OPENID_NS, 'dh_consumer_public')
        if !consumer_pubkey
          raise ProtocolError.new(message,
                  sprintf("Public key for DH-SHA1 session " +
                          "not found in message %s", message))
        end

        consumer_pubkey = CryptUtil.base64_to_num(consumer_pubkey)

        return self.new(dh, consumer_pubkey)
      end

      def answer(secret)
        mac_key = @dh.xor_secret(@hash_func,
                                 @consumer_pubkey,
                                 secret)
        return {
            'dh_server_public' => CryptUtil.num_to_base64(@dh.public),
            'enc_mac_key' => Util.to_base64(mac_key),
            }
      end
    end

    class DiffieHellmanSHA256ServerSession < DiffieHellmanSHA1ServerSession
      def initialize(*args)
        super(*args)
        @session_type = 'DH-SHA256'
        @hash_func = CryptUtil.method('sha256')
        @allowed_assoc_types = ['HMAC-SHA256'].freeze
      end
    end

    # A request to establish an association.
    #
    # See OpenID Specs, Section 8: Establishing Associations
    # <http://openid.net/specs/openid-authentication-2_0-12.html#associations>
    class AssociateRequest < OpenIDRequest
      # An object that knows how to handle association requests of a
      # certain type.
      attr_accessor :session

      # The type of association. Supported values include HMAC-SHA256
      # and HMAC-SHA1
      attr_accessor :assoc_type

      @@session_classes = {
        'no-encryption' => PlainTextServerSession,
        'DH-SHA1' => DiffieHellmanSHA1ServerSession,
        'DH-SHA256' => DiffieHellmanSHA256ServerSession,
      }

      # Construct me.
      #
      # The session is assigned directly as a class attribute. See my
      # class documentation for its description.
      def initialize(session, assoc_type)
        super()
        @session = session
        @assoc_type = assoc_type

        @mode = "associate"
      end

      # Construct me from an OpenID Message.
      def self.from_message(message, op_endpoint=UNUSED)
        if message.is_openid1()
          session_type = message.get_arg(OPENID_NS, 'session_type')
          if session_type == 'no-encryption'
            Util.log('Received OpenID 1 request with a no-encryption ' +
                     'association session type. Continuing anyway.')
          elsif !session_type
            session_type = 'no-encryption'
          end
        else
          session_type = message.get_arg(OPENID2_NS, 'session_type')
          if !session_type
            raise ProtocolError.new(message,
                                    text="session_type missing from request")
          end
        end

        session_class = @@session_classes[session_type]

        if !session_class
          raise ProtocolError.new(message,
                  sprintf("Unknown session type %s", session_type))
        end

        begin
          session = session_class.from_message(message)
        rescue ArgumentError => why
          # XXX
          raise ProtocolError.new(message,
                                  sprintf('Error parsing %s session: %s',
                                          session_type, why))
        end

        assoc_type = message.get_arg(OPENID_NS, 'assoc_type', 'HMAC-SHA1')
        if !session.allowed_assoc_type?(assoc_type)
          msg = sprintf('Session type %s does not support association type %s',
                        session_type, assoc_type)
          raise ProtocolError.new(message, msg)
        end

        obj = self.new(session, assoc_type)
        obj.message = message
        return obj
      end

      # Respond to this request with an association.
      #
      # assoc:: The association to send back.
      #
      # Returns a response with the association information, encrypted
      # to the consumer's public key if appropriate.
      def answer(assoc)
        response = OpenIDResponse.new(self)
        response.fields.update_args(OPENID_NS, {
            'expires_in' => sprintf('%d', assoc.expires_in()),
            'assoc_type' => @assoc_type,
            'assoc_handle' => assoc.handle,
            })
        response.fields.update_args(OPENID_NS,
                                   @session.answer(assoc.secret))
        unless (@session.session_type == 'no-encryption' and
                @message.is_openid1)
          response.fields.set_arg(
              OPENID_NS, 'session_type', @session.session_type)
        end

        return response
      end

      # Respond to this request indicating that the association type
      # or association session type is not supported.
      def answer_unsupported(message, preferred_association_type=nil,
                             preferred_session_type=nil)
        if @message.is_openid1()
          raise ProtocolError.new(@message)
        end

        response = OpenIDResponse.new(self)
        response.fields.set_arg(OPENID_NS, 'error_code', 'unsupported-type')
        response.fields.set_arg(OPENID_NS, 'error', message)

        if preferred_association_type
          response.fields.set_arg(
              OPENID_NS, 'assoc_type', preferred_association_type)
        end

        if preferred_session_type
          response.fields.set_arg(
              OPENID_NS, 'session_type', preferred_session_type)
        end

        return response
      end
    end

    # A request to confirm the identity of a user.
    #
    # This class handles requests for openid modes
    # +checkid_immediate+ and +checkid_setup+ .
    class CheckIDRequest < OpenIDRequest

      # Provided in smart mode requests, a handle for a previously
      # established association.  nil for dumb mode requests.
      attr_accessor :assoc_handle

      # Is this an immediate-mode request?
      attr_accessor :immediate

      # The URL to send the user agent back to to reply to this
      # request.
      attr_accessor :return_to

      # The OP-local identifier being checked.
      attr_accessor :identity

      # The claimed identifier.  Not present in OpenID 1.x
      # messages.
      attr_accessor :claimed_id

      # This URL identifies the party making the request, and the user
      # will use that to make her decision about what answer she
      # trusts them to have. Referred to as "realm" in OpenID 2.0.
      attr_accessor :trust_root

      # mode:: +checkid_immediate+ or +checkid_setup+
      attr_accessor :mode

      attr_accessor :op_endpoint

      # These parameters are assigned directly as attributes,
      # see the #CheckIDRequest class documentation for their
      # descriptions.
      #
      # Raises #MalformedReturnURL when the +return_to+ URL is not
      # a URL.
      def initialize(identity, return_to, op_endpoint, trust_root=nil,
                     immediate=false, assoc_handle=nil, claimed_id=nil)
        @assoc_handle = assoc_handle
        @identity = identity
        @claimed_id = (claimed_id or identity)
        @return_to = return_to
        @trust_root = (trust_root or return_to)
        @op_endpoint = op_endpoint
        @message = nil

        if immediate
          @immediate = true
          @mode = "checkid_immediate"
        else
          @immediate = false
          @mode = "checkid_setup"
        end

        if @return_to and
            !TrustRoot::TrustRoot.parse(@return_to)
          raise MalformedReturnURL.new(nil, @return_to)
        end

        if !trust_root_valid()
          raise UntrustedReturnURL.new(nil, @return_to, @trust_root)
        end
      end

      # Construct me from an OpenID message.
      #
      # message:: An OpenID checkid_* request Message
      #
      # op_endpoint:: The endpoint URL of the server that this
      #               message was sent to.
      #
      # Raises:
      # ProtocolError:: When not all required parameters are present
      #                 in the message.
      #
      # MalformedReturnURL:: When the +return_to+ URL is not a URL.
      #
      # UntrustedReturnURL:: When the +return_to+ URL is
      #                      outside the +trust_root+.
      def self.from_message(message, op_endpoint)
        obj = self.allocate
        obj.message = message
        obj.op_endpoint = op_endpoint
        mode = message.get_arg(OPENID_NS, 'mode')
        if mode == "checkid_immediate"
          obj.immediate = true
          obj.mode = "checkid_immediate"
        else
          obj.immediate = false
          obj.mode = "checkid_setup"
        end

        obj.return_to = message.get_arg(OPENID_NS, 'return_to')
        if message.is_openid1 and !obj.return_to
          msg = sprintf("Missing required field 'return_to' from %s",
                        message)
          raise ProtocolError.new(message, msg)
        end

        obj.identity = message.get_arg(OPENID_NS, 'identity')
        obj.claimed_id = message.get_arg(OPENID_NS, 'claimed_id')
        if message.is_openid1()
          if !obj.identity
            s = "OpenID 1 message did not contain openid.identity"
            raise ProtocolError.new(message, s)
          end
        else
          if obj.identity and not obj.claimed_id
            s = ("OpenID 2.0 message contained openid.identity but not " +
                 "claimed_id")
            raise ProtocolError.new(message, s)
          elsif obj.claimed_id and not obj.identity
            s = ("OpenID 2.0 message contained openid.claimed_id but not " +
                 "identity")
            raise ProtocolError.new(message, s)
          end
        end

        # There's a case for making self.trust_root be a TrustRoot
        # here.  But if TrustRoot isn't currently part of the "public"
        # API, I'm not sure it's worth doing.
        if message.is_openid1
          trust_root_param = 'trust_root'
        else
          trust_root_param = 'realm'
        end
        trust_root = message.get_arg(OPENID_NS, trust_root_param)
        trust_root = obj.return_to if (trust_root.nil? || trust_root.empty?)
        obj.trust_root = trust_root

        if !message.is_openid1 and !obj.return_to and !obj.trust_root
          raise ProtocolError.new(message, "openid.realm required when " +
                                  "openid.return_to absent")
        end

        obj.assoc_handle = message.get_arg(OPENID_NS, 'assoc_handle')

        # Using TrustRoot.parse here is a bit misleading, as we're not
        # parsing return_to as a trust root at all.  However, valid
        # URLs are valid trust roots, so we can use this to get an
        # idea if it is a valid URL.  Not all trust roots are valid
        # return_to URLs, however (particularly ones with wildcards),
        # so this is still a little sketchy.
        if obj.return_to and \
          !TrustRoot::TrustRoot.parse(obj.return_to)
          raise MalformedReturnURL.new(message, obj.return_to)
        end

        # I first thought that checking to see if the return_to is
        # within the trust_root is premature here, a
        # logic-not-decoding thing.  But it was argued that this is
        # really part of data validation.  A request with an invalid
        # trust_root/return_to is broken regardless of application,
        # right?
        if !obj.trust_root_valid()
          raise UntrustedReturnURL.new(message, obj.return_to, obj.trust_root)
        end

        return obj
      end

      # Is the identifier to be selected by the IDP?
      def id_select
        # So IDPs don't have to import the constant
        return @identity == IDENTIFIER_SELECT
      end

      # Is my return_to under my trust_root?
      def trust_root_valid
        if !@trust_root
          return true
        end

        tr = TrustRoot::TrustRoot.parse(@trust_root)
        if !tr
          raise MalformedTrustRoot.new(@message, @trust_root)
        end

        if @return_to
          return tr.validate_url(@return_to)
        else
          return true
        end
      end

      # Does the relying party publish the return_to URL for this
      # response under the realm? It is up to the provider to set a
      # policy for what kinds of realms should be allowed. This
      # return_to URL verification reduces vulnerability to
      # data-theft attacks based on open proxies,
      # corss-site-scripting, or open redirectors.
      #
      # This check should only be performed after making sure that
      # the return_to URL matches the realm.
      #
      # Raises DiscoveryFailure if the realm
      # URL does not support Yadis discovery (and so does not
      # support the verification process).
      #
      # Returns true if the realm publishes a document with the
      # return_to URL listed
      def return_to_verified
        return TrustRoot.verify_return_to(@trust_root, @return_to)
      end

      # Respond to this request.
      #
      # allow:: Allow this user to claim this identity, and allow the
      #         consumer to have this information?
      #
      # server_url:: DEPRECATED.  Passing op_endpoint to the
      #              #Server constructor makes this optional.
      #
      #              When an OpenID 1.x immediate mode request does
      #              not succeed, it gets back a URL where the request
      #              may be carried out in a not-so-immediate fashion.
      #              Pass my URL in here (the fully qualified address
      #              of this server's endpoint, i.e.
      #              <tt>http://example.com/server</tt>), and I will
      #              use it as a base for the URL for a new request.
      #
      #              Optional for requests where
      #              #CheckIDRequest.immediate is false or +allow+ is
      #              true.
      #
      # identity:: The OP-local identifier to answer with.  Only for use
      #            when the relying party requested identifier selection.
      #
      # claimed_id:: The claimed identifier to answer with,
      #              for use with identifier selection in the case where the
      #              claimed identifier and the OP-local identifier differ,
      #              i.e. when the claimed_id uses delegation.
      #
      #              If +identity+ is provided but this is not,
      #              +claimed_id+ will default to the value of +identity+.
      #              When answering requests that did not ask for identifier
      #              selection, the response +claimed_id+ will default to
      #              that of the request.
      #
      #              This parameter is new in OpenID 2.0.
      #
      # Returns an OpenIDResponse object containing a OpenID id_res message.
      #
      # Raises NoReturnToError if the return_to is missing.
      #
      # Version 2.0 deprecates +server_url+ and adds +claimed_id+.
      def answer(allow, server_url=nil, identity=nil, claimed_id=nil)
        if !@return_to
          raise NoReturnToError
        end

        if !server_url
          if @message.is_openid2 and !@op_endpoint
            # In other words, that warning I raised in
            # Server.__init__?  You should pay attention to it now.
            raise RuntimeError, ("#{self} should be constructed with "\
                                 "op_endpoint to respond to OpenID 2.0 "\
                                 "messages.")
          end

          server_url = @op_endpoint
        end

        if allow
          mode = 'id_res'
        elsif @message.is_openid1
          if @immediate
            mode = 'id_res'
          else
            mode = 'cancel'
          end
        else
          if @immediate
            mode = 'setup_needed'
          else
            mode = 'cancel'
          end
        end

        response = OpenIDResponse.new(self)

        if claimed_id and @message.is_openid1
          raise VersionError, ("claimed_id is new in OpenID 2.0 and not "\
                               "available for #{@message.get_openid_namespace}")
        end

        if identity and !claimed_id
          claimed_id = identity
        end

        if allow
          if @identity == IDENTIFIER_SELECT
            if !identity
              raise ArgumentError, ("This request uses IdP-driven "\
                                    "identifier selection.You must supply "\
                                    "an identifier in the response.")
            end

            response_identity = identity
            response_claimed_id = claimed_id

          elsif @identity
            if identity and (@identity != identity)
              raise ArgumentError, ("Request was for identity #{@identity}, "\
                                    "cannot reply with identity #{identity}")
            end

            response_identity = @identity
            response_claimed_id = @claimed_id
          else
            if identity
              raise ArgumentError, ("This request specified no identity "\
                                    "and you supplied #{identity}")
            end
            response_identity = nil
          end

          if @message.is_openid1 and !response_identity
            raise ArgumentError, ("Request was an OpenID 1 request, so "\
                                  "response must include an identifier.")
          end

          response.fields.update_args(OPENID_NS, {
                'mode' => mode,
                'op_endpoint' => server_url,
                'return_to' => @return_to,
                'response_nonce' => Nonce.mk_nonce(),
                })

          if response_identity
            response.fields.set_arg(OPENID_NS, 'identity', response_identity)
            if @message.is_openid2
              response.fields.set_arg(OPENID_NS,
                                      'claimed_id', response_claimed_id)
            end
          end
        else
          response.fields.set_arg(OPENID_NS, 'mode', mode)
          if @immediate
            if @message.is_openid1 and !server_url
              raise ArgumentError, ("setup_url is required for allow=false "\
                                    "in OpenID 1.x immediate mode.")
            end

            # Make a new request just like me, but with
            # immediate=false.
            setup_request = self.class.new(@identity, @return_to,
                                           @op_endpoint, @trust_root, false,
                                           @assoc_handle, @claimed_id)
            setup_request.message = Message.new(@message.get_openid_namespace)
            setup_url = setup_request.encode_to_url(server_url)
            response.fields.set_arg(OPENID_NS, 'user_setup_url', setup_url)
          end
        end

        return response
      end

      def encode_to_url(server_url)
        # Encode this request as a URL to GET.
        #
        # server_url:: The URL of the OpenID server to make this
        #              request of.
        if !@return_to
          raise NoReturnToError
        end

        # Imported from the alternate reality where these classes are
        # used in both the client and server code, so Requests are
        # Encodable too.  That's right, code imported from alternate
        # realities all for the love of you, id_res/user_setup_url.
        q = {'mode' => @mode,
             'identity' => @identity,
             'claimed_id' => @claimed_id,
             'return_to' => @return_to}

        if @trust_root
          if @message.is_openid1
            q['trust_root'] = @trust_root
          else
            q['realm'] = @trust_root
          end
        end

        if @assoc_handle
          q['assoc_handle'] = @assoc_handle
        end

        response = Message.new(@message.get_openid_namespace)
        response.update_args(@message.get_openid_namespace, q)
        return response.to_url(server_url)
      end

      def cancel_url
        # Get the URL to cancel this request.
        #
        # Useful for creating a "Cancel" button on a web form so that
        # operation can be carried out directly without another trip
        # through the server.
        #
        # (Except you may want to make another trip through the
        # server so that it knows that the user did make a decision.)
        #
        # Returns a URL as a string.
        if !@return_to
          raise NoReturnToError
        end

        if @immediate
          raise ArgumentError.new("Cancel is not an appropriate response to " +
                                  "immediate mode requests.")
        end

        response = Message.new(@message.get_openid_namespace)
        response.set_arg(OPENID_NS, 'mode', 'cancel')
        return response.to_url(@return_to)
      end

      def to_s
        return sprintf('<%s id:%s im:%s tr:%s ah:%s>', self.class,
                       @identity,
                       @immediate,
                       @trust_root,
                       @assoc_handle)
      end
    end

    # I am a response to an OpenID request.
    #
    # Attributes:
    # signed:: A list of the names of the fields which should be signed.
    #
    # Implementer's note: In a more symmetric client/server
    # implementation, there would be more types of #OpenIDResponse
    # object and they would have validated attributes according to
    # the type of response.  But as it is, Response objects in a
    # server are basically write-only, their only job is to go out
    # over the wire, so this is just a loose wrapper around
    # #OpenIDResponse.fields.
    class OpenIDResponse
      # The #OpenIDRequest I respond to.
      attr_accessor :request

      # An #OpenID::Message with the data to be returned.
      # Keys are parameter names with no
      # leading openid. e.g. identity and mac_key
      # never openid.identity.
      attr_accessor :fields

      def initialize(request)
        # Make a response to an OpenIDRequest.
        @request = request
        @fields = Message.new(request.namespace)
      end

      def to_s
        return sprintf("%s for %s: %s",
                       self.class,
                       @request.class,
                       @fields)
      end

      # form_tag_attrs is a hash of attributes to be added to the form
      # tag. 'accept-charset' and 'enctype' have defaults that can be
      # overridden. If a value is supplied for 'action' or 'method',
      # it will be replaced.       
      # Returns the form markup for this response.
      def to_form_markup(form_tag_attrs=nil)
        return @fields.to_form_markup(@request.return_to, form_tag_attrs)
      end

      # Wraps the form tag from to_form_markup in a complete HTML document
      # that uses javascript to autosubmit the form.
      def to_html(form_tag_attrs=nil)
        return Util.auto_submit_html(to_form_markup(form_tag_attrs))
      end

      def render_as_form
        # Returns true if this response's encoding is
        # ENCODE_HTML_FORM.  Convenience method for server authors.
        return self.which_encoding == ENCODE_HTML_FORM
      end

      def needs_signing
        # Does this response require signing?
        return @fields.get_arg(OPENID_NS, 'mode') == 'id_res'
      end

      # implements IEncodable

      def which_encoding
        # How should I be encoded?
        # returns one of ENCODE_URL or ENCODE_KVFORM.
        if BROWSER_REQUEST_MODES.member?(@request.mode)
          if @fields.is_openid2 and
              encode_to_url.length > OPENID1_URL_LIMIT
            return ENCODE_HTML_FORM
          else
            return ENCODE_URL
          end
        else
          return ENCODE_KVFORM
        end
      end

      def encode_to_url
        # Encode a response as a URL for the user agent to GET.
        # You will generally use this URL with a HTTP redirect.
        return @fields.to_url(@request.return_to)
      end

      def add_extension(extension_response)
        # Add an extension response to this response message.
        #
        # extension_response:: An object that implements the
        #     #OpenID::Extension interface for adding arguments to an OpenID
        #     message.
        extension_response.to_message(@fields)
      end

      def encode_to_kvform
        # Encode a response in key-value colon/newline format.
        #
        # This is a machine-readable format used to respond to
        # messages which came directly from the consumer and not
        # through the user agent.
        #
        # see: OpenID Specs,
        #    <a href="http://openid.net/specs.bml#keyvalue">Key-Value Colon/Newline format</a>
        return @fields.to_kvform
      end

      def copy
        return Marshal.load(Marshal.dump(self))
      end
    end

    # I am a response to an OpenID request in terms a web server
    # understands.
    #
    # I generally come from an #Encoder, either directly or from
    # #Server.encodeResponse.
    class WebResponse

      # The HTTP code of this response as an integer.
      attr_accessor :code

      # #Hash of headers to include in this response.
      attr_accessor :headers

      # The body of this response.
      attr_accessor :body

      def initialize(code=HTTP_OK, headers=nil, body="")
        # Construct me.
        #
        # These parameters are assigned directly as class attributes,
        # see my class documentation for their
        # descriptions.
        @code = code
        if headers
          @headers = headers
        else
          @headers = {}
        end
        @body = body
      end
    end

    # I sign things.
    #
    # I also check signatures.
    #
    # All my state is encapsulated in a store, which means I'm not
    # generally pickleable but I am easy to reconstruct.
    class Signatory
      # The number of seconds a secret remains valid. Defaults to 14 days.
      attr_accessor :secret_lifetime

      # keys have a bogus server URL in them because the filestore
      # really does expect that key to be a URL.  This seems a little
      # silly for the server store, since I expect there to be only
      # one server URL.
      @@_normal_key = 'http://localhost/|normal'
      @@_dumb_key = 'http://localhost/|dumb'

      def self._normal_key
        @@_normal_key
      end

      def self._dumb_key
        @@_dumb_key
      end

      attr_accessor :store

      # Create a new Signatory. store is The back-end where my
      # associations are stored.
      def initialize(store)
        Util.assert(store)
        @store = store
        @secret_lifetime = 14 * 24 * 60 * 60
      end

      # Verify that the signature for some data is valid.
      def verify(assoc_handle, message)
        assoc = get_association(assoc_handle, true)
        if !assoc
          Util.log(sprintf("failed to get assoc with handle %s to verify " +
                           "message %s", assoc_handle, message))
          return false
        end

        begin
          valid = assoc.check_message_signature(message)
        rescue StandardError => ex
          Util.log(sprintf("Error in verifying %s with %s: %s",
                           message, assoc, ex))
          return false
        end

        return valid
      end

      # Sign a response.
      #
      # I take an OpenIDResponse, create a signature for everything in
      # its signed list, and return a new copy of the response object
      # with that signature included.
      def sign(response)
        signed_response = response.copy
        assoc_handle = response.request.assoc_handle
        if assoc_handle
          # normal mode disabling expiration check because even if the
          # association is expired, we still need to know some
          # properties of the association so that we may preserve
          # those properties when creating the fallback association.
          assoc = get_association(assoc_handle, false, false)

          if !assoc or assoc.expires_in <= 0
            # fall back to dumb mode
            signed_response.fields.set_arg(
                  OPENID_NS, 'invalidate_handle', assoc_handle)
            assoc_type = assoc ? assoc.assoc_type : 'HMAC-SHA1'
            if assoc and assoc.expires_in <= 0
              # now do the clean-up that the disabled checkExpiration
              # code didn't get to do.
              invalidate(assoc_handle, false)
            end
            assoc = create_association(true, assoc_type)
          end
        else
          # dumb mode.
          assoc = create_association(true)
        end

        begin
          signed_response.fields = assoc.sign_message(signed_response.fields)
        rescue KVFormError => err
          raise EncodingError, err
        end
        return signed_response
      end

      # Make a new association.
      def create_association(dumb=true, assoc_type='HMAC-SHA1')
        secret = CryptUtil.random_string(OpenID.get_secret_size(assoc_type))
        uniq = Util.to_base64(CryptUtil.random_string(4))
        handle = sprintf('{%s}{%x}{%s}', assoc_type, Time.now.to_i, uniq)

        assoc = Association.from_expires_in(
            secret_lifetime, handle, secret, assoc_type)

        if dumb
          key = @@_dumb_key
        else
          key = @@_normal_key
        end

        @store.store_association(key, assoc)
        return assoc
      end

      # Get the association with the specified handle.
      def get_association(assoc_handle, dumb, checkExpiration=true)
        # Hmm.  We've created an interface that deals almost entirely
        # with assoc_handles.  The only place outside the Signatory
        # that uses this (and thus the only place that ever sees
        # Association objects) is when creating a response to an
        # association request, as it must have the association's
        # secret.

        if !assoc_handle
          raise ArgumentError.new("assoc_handle must not be None")
        end

        if dumb
          key = @@_dumb_key
        else
          key = @@_normal_key
        end

        assoc = @store.get_association(key, assoc_handle)
        if assoc and assoc.expires_in <= 0
          Util.log(sprintf("requested %sdumb key %s is expired (by %s seconds)",
                           (!dumb) ? 'not-' : '',
                           assoc_handle, assoc.expires_in))
          if checkExpiration
            @store.remove_association(key, assoc_handle)
            assoc = nil
          end
        end

        return assoc
      end

      # Invalidates the association with the given handle.
      def invalidate(assoc_handle, dumb)
        if dumb
          key = @@_dumb_key
        else
          key = @@_normal_key
        end

        @store.remove_association(key, assoc_handle)
      end
    end

    # I encode responses in to WebResponses.
    #
    # If you don't like WebResponses, you can do
    # your own handling of OpenIDResponses with
    # OpenIDResponse.whichEncoding,
    # OpenIDResponse.encodeToURL, and
    # OpenIDResponse.encodeToKVForm.
    class Encoder
      @@responseFactory = WebResponse

      # Encode a response to a WebResponse.
      #
      # Raises EncodingError when I can't figure out how to encode
      # this message.
      def encode(response)
        encode_as = response.which_encoding()
        if encode_as == ENCODE_KVFORM
          wr = @@responseFactory.new(HTTP_OK, nil,
                                     response.encode_to_kvform())
          if response.is_a?(Exception)
            wr.code = HTTP_ERROR
          end
        elsif encode_as == ENCODE_URL
          location = response.encode_to_url()
          wr = @@responseFactory.new(HTTP_REDIRECT,
                                     {'location' => location})
        elsif encode_as == ENCODE_HTML_FORM
          wr = @@responseFactory.new(HTTP_OK, nil,
                                     response.to_form_markup())
        else
          # Can't encode this to a protocol message.  You should
          # probably render it to HTML and show it to the user.
          raise EncodingError.new(response)
        end

        return wr
      end
    end

    # I encode responses in to WebResponses, signing
    # them when required.
    class SigningEncoder < Encoder

      attr_accessor :signatory

      # Create a SigningEncoder given a Signatory
      def initialize(signatory)
        @signatory = signatory
      end

      # Encode a response to a WebResponse, signing it first if
      # appropriate.
      #
      # Raises EncodingError when I can't figure out how to encode this
      # message.
      #
      # Raises AlreadySigned when this response is already signed.
      def encode(response)
        # the is_a? is a bit of a kludge... it means there isn't
        # really an adapter to make the interfaces quite match.
        if !response.is_a?(Exception) and response.needs_signing()
          if !@signatory
            raise ArgumentError.new(
              sprintf("Must have a store to sign this request: %s",
                      response), response)
          end

          if response.fields.has_key?(OPENID_NS, 'sig')
            raise AlreadySigned.new(response)
          end

          response = @signatory.sign(response)
        end

        return super(response)
      end
    end

    # I decode an incoming web request in to a OpenIDRequest.
    class Decoder

      @@handlers = {
        'checkid_setup' => CheckIDRequest.method('from_message'),
        'checkid_immediate' => CheckIDRequest.method('from_message'),
        'check_authentication' => CheckAuthRequest.method('from_message'),
        'associate' => AssociateRequest.method('from_message'),
        }

      attr_accessor :server

      # Construct a Decoder. The server is necessary because some
      # replies reference their server.
      def initialize(server)
        @server = server
      end

      # I transform query parameters into an OpenIDRequest.
      #
      # If the query does not seem to be an OpenID request at all, I
      # return nil.
      #
      # Raises ProtocolError when the query does not seem to be a valid
      # OpenID request.
      def decode(query)
        if query.nil? or query.length == 0
          return nil
        end

        begin
          message = Message.from_post_args(query)
        rescue InvalidOpenIDNamespace => e
          query = query.dup
          query['openid.ns'] = OPENID2_NS
          message = Message.from_post_args(query)
          raise ProtocolError.new(message, e.to_s)
        end

        mode = message.get_arg(OPENID_NS, 'mode')
        if !mode
          msg = sprintf("No mode value in message %s", message)
          raise ProtocolError.new(message, msg)
        end

        handler = @@handlers.fetch(mode, self.method('default_decoder'))
        return handler.call(message, @server.op_endpoint)
      end

      # Called to decode queries when no handler for that mode is
      # found.
      #
      # This implementation always raises ProtocolError.
      def default_decoder(message, server)
        mode = message.get_arg(OPENID_NS, 'mode')
        msg = sprintf("Unrecognized OpenID mode %s", mode)
        raise ProtocolError.new(message, msg)
      end
    end

    # I handle requests for an OpenID server.
    #
    # Some types of requests (those which are not checkid requests)
    # may be handed to my handleRequest method, and I will take care
    # of it and return a response.
    #
    # For your convenience, I also provide an interface to
    # Decoder.decode and SigningEncoder.encode through my methods
    # decodeRequest and encodeResponse.
    #
    # All my state is encapsulated in an store, which means I'm not
    # generally pickleable but I am easy to reconstruct.
    class Server
      @@signatoryClass = Signatory
      @@encoderClass = SigningEncoder
      @@decoderClass = Decoder

      # The back-end where my associations and nonces are stored.
      attr_accessor :store

      # I'm using this for associate requests and to sign things.
      attr_accessor :signatory

      # I'm using this to encode things.
      attr_accessor :encoder

      # I'm using this to decode things.
      attr_accessor :decoder

      # I use this instance of OpenID::AssociationNegotiator to
      # determine which kinds of associations I can make and how.
      attr_accessor :negotiator

      # My URL.
      attr_accessor :op_endpoint

      # op_endpoint is new in library version 2.0.
      def initialize(store, op_endpoint)
        @store = store
        @signatory = @@signatoryClass.new(@store)
        @encoder = @@encoderClass.new(@signatory)
        @decoder = @@decoderClass.new(self)
        @negotiator = DefaultNegotiator.copy()
        @op_endpoint = op_endpoint
      end

      # Handle a request.
      #
      # Give me a request, I will give you a response.  Unless it's a
      # type of request I cannot handle myself, in which case I will
      # raise RuntimeError.  In that case, you can handle it yourself,
      # or add a method to me for handling that request type.
      def handle_request(request)
        begin
          handler = self.method('openid_' + request.mode)
        rescue NameError
          raise RuntimeError.new(
            sprintf("%s has no handler for a request of mode %s.",
                    self, request.mode))
        end

        return handler.call(request)
      end

      # Handle and respond to check_authentication requests.
      def openid_check_authentication(request)
        return request.answer(@signatory)
      end

      # Handle and respond to associate requests.
      def openid_associate(request)
        assoc_type = request.assoc_type
        session_type = request.session.session_type
        if @negotiator.allowed?(assoc_type, session_type)
          assoc = @signatory.create_association(false,
                                                assoc_type)
          return request.answer(assoc)
        else
          message = sprintf('Association type %s is not supported with ' +
                            'session type %s', assoc_type, session_type)
          preferred_assoc_type, preferred_session_type = @negotiator.get_allowed_type()
          return request.answer_unsupported(message,
                                            preferred_assoc_type,
                                            preferred_session_type)
        end
      end

      # Transform query parameters into an OpenIDRequest.
      # query should contain the query parameters as a Hash with
      # each key mapping to one value.
      #
      # If the query does not seem to be an OpenID request at all, I
      # return nil.
      def decode_request(query)
        return @decoder.decode(query)
      end

      # Encode a response to a WebResponse, signing it first if
      # appropriate.
      #
      # Raises EncodingError when I can't figure out how to encode this
      # message.
      #
      # Raises AlreadySigned When this response is already signed.
      def encode_response(response)
        return @encoder.encode(response)
      end
    end

    # A message did not conform to the OpenID protocol.
    class ProtocolError < Exception
      # The query that is failing to be a valid OpenID request.
      attr_accessor :openid_message
      attr_accessor :reference
      attr_accessor :contact

      # text:: A message about the encountered error.
      def initialize(message, text=nil, reference=nil, contact=nil)
        @openid_message = message
        @reference = reference
        @contact = contact
        Util.assert(!message.is_a?(String))
        super(text)
      end

      # Get the return_to argument from the request, if any.
      def get_return_to
        if @openid_message.nil?
          return nil
        else
          return @openid_message.get_arg(OPENID_NS, 'return_to')
        end
      end

      # Did this request have a return_to parameter?
      def has_return_to
        return !get_return_to.nil?
      end

      # Generate a Message object for sending to the relying party,
      # after encoding.
      def to_message
        namespace = @openid_message.get_openid_namespace()
        reply = Message.new(namespace)
        reply.set_arg(OPENID_NS, 'mode', 'error')
        reply.set_arg(OPENID_NS, 'error', self.to_s)

        if @contact
          reply.set_arg(OPENID_NS, 'contact', @contact.to_s)
        end

        if @reference
          reply.set_arg(OPENID_NS, 'reference', @reference.to_s)
        end

        return reply
      end

      # implements IEncodable

      def encode_to_url
        return to_message().to_url(get_return_to())
      end

      def encode_to_kvform
        return to_message().to_kvform()
      end

      def to_form_markup
        return to_message().to_form_markup(get_return_to())
      end

      def to_html
        return Util.auto_submit_html(to_form_markup)
      end

      # How should I be encoded?
      #
      # Returns one of ENCODE_URL, ENCODE_KVFORM, or None.  If None,
      # I cannot be encoded as a protocol message and should be
      # displayed to the user.
      def which_encoding
        if has_return_to()
          if @openid_message.is_openid2 and
              encode_to_url().length > OPENID1_URL_LIMIT
            return ENCODE_HTML_FORM
          else
            return ENCODE_URL
          end
        end

        if @openid_message.nil?
          return nil
        end

        mode = @openid_message.get_arg(OPENID_NS, 'mode')
        if mode
          if !BROWSER_REQUEST_MODES.member?(mode)
            return ENCODE_KVFORM
          end
        end

        # If your request was so broken that you didn't manage to
        # include an openid.mode, I'm not going to worry too much
        # about returning you something you can't parse.
        return nil
      end
    end

    # Raised when an operation was attempted that is not compatible
    # with the protocol version being used.
    class VersionError < Exception
    end

    # Raised when a response to a request cannot be generated
    # because the request contains no return_to URL.
    class NoReturnToError < Exception
    end

    # Could not encode this as a protocol message.
    #
    # You should probably render it and show it to the user.
    class EncodingError < Exception
      # The response that failed to encode.
      attr_reader :response

      def initialize(response)
        super(response)
        @response = response
      end
    end

    # This response is already signed.
    class AlreadySigned < EncodingError
    end

    # A return_to is outside the trust_root.
    class UntrustedReturnURL < ProtocolError
      attr_reader :return_to, :trust_root

      def initialize(message, return_to, trust_root)
        super(message)
        @return_to = return_to
        @trust_root = trust_root
      end

      def to_s
        return sprintf("return_to %s not under trust_root %s",
                       @return_to,
                       @trust_root)
      end
    end

    # The return_to URL doesn't look like a valid URL.
    class MalformedReturnURL < ProtocolError
      attr_reader :return_to

      def initialize(openid_message, return_to)
        @return_to = return_to
        super(openid_message)
      end
    end

    # The trust root is not well-formed.
    class MalformedTrustRoot < ProtocolError
    end
  end
end
