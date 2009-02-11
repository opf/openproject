require "openid/dh"
require "openid/util"
require "openid/kvpost"
require "openid/cryptutil"
require "openid/protocolerror"
require "openid/association"

module OpenID
  class Consumer

    # A superclass for implementing Diffie-Hellman association sessions.
    class DiffieHellmanSession
      class << self
        attr_reader :session_type, :secret_size, :allowed_assoc_types,
          :hashfunc
      end

      def initialize(dh=nil)
        if dh.nil?
          dh = DiffieHellman.from_defaults
        end
        @dh = dh
      end

      # Return the query parameters for requesting an association
      # using this Diffie-Hellman association session
      def get_request
        args = {'dh_consumer_public' => CryptUtil.num_to_base64(@dh.public)}
        if (!@dh.using_default_values?)
          args['dh_modulus'] = CryptUtil.num_to_base64(@dh.modulus)
          args['dh_gen'] = CryptUtil.num_to_base64(@dh.generator)
        end

        return args
      end

      # Process the response from a successful association request and
      # return the shared secret for this association
      def extract_secret(response)
        dh_server_public64 = response.get_arg(OPENID_NS, 'dh_server_public',
                                              NO_DEFAULT)
        enc_mac_key64 = response.get_arg(OPENID_NS, 'enc_mac_key', NO_DEFAULT)
        dh_server_public = CryptUtil.base64_to_num(dh_server_public64)
        enc_mac_key = Util.from_base64(enc_mac_key64)
        return @dh.xor_secret(self.class.hashfunc,
                              dh_server_public, enc_mac_key)
      end
    end

    # A Diffie-Hellman association session that uses SHA1 as its hash
    # function
    class DiffieHellmanSHA1Session < DiffieHellmanSession
      @session_type = 'DH-SHA1'
      @secret_size = 20
      @allowed_assoc_types = ['HMAC-SHA1']
      @hashfunc = CryptUtil.method(:sha1)
    end

    # A Diffie-Hellman association session that uses SHA256 as its hash
    # function
    class DiffieHellmanSHA256Session < DiffieHellmanSession
      @session_type = 'DH-SHA256'
      @secret_size = 32
      @allowed_assoc_types = ['HMAC-SHA256']
      @hashfunc = CryptUtil.method(:sha256)
    end

    # An association session that does not use encryption
    class NoEncryptionSession
      class << self
        attr_reader :session_type, :allowed_assoc_types
      end
      @session_type = 'no-encryption'
      @allowed_assoc_types = ['HMAC-SHA1', 'HMAC-SHA256']

      def get_request
        return {}
      end

      def extract_secret(response)
        mac_key64 = response.get_arg(OPENID_NS, 'mac_key', NO_DEFAULT)
        return Util.from_base64(mac_key64)
      end
    end

    # An object that manages creating and storing associations for an
    # OpenID provider endpoint
    class AssociationManager
      def self.create_session(session_type)
        case session_type
        when 'no-encryption'
          NoEncryptionSession.new
        when 'DH-SHA1'
          DiffieHellmanSHA1Session.new
        when 'DH-SHA256'
          DiffieHellmanSHA256Session.new
        else
          raise ArgumentError, "Unknown association session type: "\
                               "#{session_type.inspect}"
        end
      end

      def initialize(store, server_url, compatibility_mode=false,
                     negotiator=nil)
        @store = store
        @server_url = server_url
        @compatibility_mode = compatibility_mode
        @negotiator = negotiator || DefaultNegotiator
      end

      def get_association
        if @store.nil?
          return nil
        end

        assoc = @store.get_association(@server_url)
        if assoc.nil? || assoc.expires_in <= 0
          assoc = negotiate_association
          if !assoc.nil?
            @store.store_association(@server_url, assoc)
          end
        end

        return assoc
      end

      def negotiate_association
        assoc_type, session_type = @negotiator.get_allowed_type
        begin
          return request_association(assoc_type, session_type)
        rescue ServerError => why
          supported_types = extract_supported_association_type(why, assoc_type)
          if !supported_types.nil?
            # Attempt to create an association from the assoc_type and
            # session_type that the server told us it supported.
            assoc_type, session_type = supported_types
            begin
              return request_association(assoc_type, session_type)
            rescue ServerError => why
              Util.log("Server #{@server_url} refused its suggested " \
                       "association type: session_type=#{session_type}, " \
                       "assoc_type=#{assoc_type}")
              return nil
            end
          end
        end
      end

      protected
      def extract_supported_association_type(server_error, assoc_type)
        # Any error message whose code is not 'unsupported-type' should
        # be considered a total failure.
        if (server_error.error_code != 'unsupported-type' or
            server_error.message.is_openid1)
          Util.log("Server error when requesting an association from "\
                   "#{@server_url}: #{server_error.error_text}")
          return nil
        end

        # The server didn't like the association/session type that we
        # sent, and it sent us back a message that might tell us how to
        # handle it.
        Util.log("Unsupported association type #{assoc_type}: "\
                 "#{server_error.error_text}")

        # Extract the session_type and assoc_type from the error message
        assoc_type = server_error.message.get_arg(OPENID_NS, 'assoc_type')
        session_type = server_error.message.get_arg(OPENID_NS, 'session_type')

        if assoc_type.nil? or session_type.nil?
          Util.log("Server #{@server_url} responded with unsupported "\
                   "association session but did not supply a fallback.")
          return nil
        elsif !@negotiator.allowed?(assoc_type, session_type)
          Util.log("Server sent unsupported session/association type: "\
                   "session_type=#{session_type}, assoc_type=#{assoc_type}")
          return nil
        else
          return [assoc_type, session_type]
        end
      end

      # Make and process one association request to this endpoint's OP
      # endpoint URL. Returns an association object or nil if the
      # association processing failed. Raises ServerError when the
      # remote OpenID server returns an error.
      def request_association(assoc_type, session_type)
        assoc_session, args = create_associate_request(assoc_type, session_type)

        begin
          response = OpenID.make_kv_post(args, @server_url)
          return extract_association(response, assoc_session)
        rescue HTTPStatusError => why
          Util.log("Got HTTP status error when requesting association: #{why}")
          return nil
        rescue Message::KeyNotFound => why
          Util.log("Missing required parameter in response from "\
                   "#{@server_url}: #{why}")
          return nil

        rescue ProtocolError => why
          Util.log("Protocol error processing response from #{@server_url}: "\
                   "#{why}")
          return nil
        end
      end

      # Create an association request for the given assoc_type and
      # session_type. Returns a pair of the association session object
      # and the request message that will be sent to the server.
      def create_associate_request(assoc_type, session_type)
        assoc_session = self.class.create_session(session_type)
        args = {
          'mode' => 'associate',
          'assoc_type' => assoc_type,
        }

        if !@compatibility_mode
          args['ns'] = OPENID2_NS
        end

        # Leave out the session type if we're in compatibility mode
        # *and* it's no-encryption.
        if !@compatibility_mode ||
            assoc_session.class.session_type != 'no-encryption'
          args['session_type'] = assoc_session.class.session_type
        end

        args.merge!(assoc_session.get_request)
        message = Message.from_openid_args(args)
        return assoc_session, message
      end

      # Given an association response message, extract the OpenID 1.X
      # session type. Returns the association type for this message
      #
      # This function mostly takes care of the 'no-encryption' default
      # behavior in OpenID 1.
      #
      # If the association type is plain-text, this function will
      # return 'no-encryption'
      def get_openid1_session_type(assoc_response)
        # If it's an OpenID 1 message, allow session_type to default
        # to nil (which signifies "no-encryption")
        session_type = assoc_response.get_arg(OPENID1_NS, 'session_type')

        # Handle the differences between no-encryption association
        # respones in OpenID 1 and 2:

        # no-encryption is not really a valid session type for
        # OpenID 1, but we'll accept it anyway, while issuing a
        # warning.
        if session_type == 'no-encryption'
          Util.log("WARNING: #{@server_url} sent 'no-encryption'"\
                   "for OpenID 1.X")

        # Missing or empty session type is the way to flag a
        # 'no-encryption' response. Change the session type to
        # 'no-encryption' so that it can be handled in the same
        # way as OpenID 2 'no-encryption' respones.
        elsif session_type == '' || session_type.nil?
          session_type = 'no-encryption'
        end

        return session_type
      end

      def self.extract_expires_in(message)
        # expires_in should be a base-10 string.
        expires_in_str = message.get_arg(OPENID_NS, 'expires_in', NO_DEFAULT)
        if !(/\A\d+\Z/ =~ expires_in_str)
          raise ProtocolError, "Invalid expires_in field: #{expires_in_str}"
        end
        expires_in_str.to_i
      end

      # Attempt to extract an association from the response, given the
      # association response message and the established association
      # session.
      def extract_association(assoc_response, assoc_session)
        # Extract the common fields from the response, raising an
        # exception if they are not found
        assoc_type = assoc_response.get_arg(OPENID_NS, 'assoc_type',
                                            NO_DEFAULT)
        assoc_handle = assoc_response.get_arg(OPENID_NS, 'assoc_handle',
                                              NO_DEFAULT)
        expires_in = self.class.extract_expires_in(assoc_response)

        # OpenID 1 has funny association session behaviour.
        if assoc_response.is_openid1
            session_type = get_openid1_session_type(assoc_response)
        else
          session_type = assoc_response.get_arg(OPENID2_NS, 'session_type',
                                                NO_DEFAULT)
        end

        # Session type mismatch
        if assoc_session.class.session_type != session_type
          if (assoc_response.is_openid1 and session_type == 'no-encryption')
            # In OpenID 1, any association request can result in a
            # 'no-encryption' association response. Setting
            # assoc_session to a new no-encryption session should
            # make the rest of this function work properly for
            # that case.
            assoc_session = NoEncryptionSession.new
          else
            # Any other mismatch, regardless of protocol version
            # results in the failure of the association session
            # altogether.
            raise ProtocolError, "Session type mismatch. Expected "\
                                 "#{assoc_session.class.session_type}, got "\
                                 "#{session_type}"
          end
        end

        # Make sure assoc_type is valid for session_type
        if !assoc_session.class.allowed_assoc_types.member?(assoc_type)
          raise ProtocolError, "Unsupported assoc_type for session "\
                               "#{assoc_session.class.session_type} "\
                               "returned: #{assoc_type}"
        end

        # Delegate to the association session to extract the secret
        # from the response, however is appropriate for that session
        # type.
        begin
          secret = assoc_session.extract_secret(assoc_response)
        rescue Message::KeyNotFound, ArgumentError => why
          raise ProtocolError, "Malformed response for "\
                               "#{assoc_session.class.session_type} "\
                               "session: #{why.message}"
        end


        return Association.from_expires_in(expires_in, assoc_handle, secret,
                                           assoc_type)
      end
    end
  end
end
