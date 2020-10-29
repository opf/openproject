module OpenIDConnect
  class Client
    class Registrar
      include ActiveModel::Validations, AttrRequired, AttrOptional

      class RegistrationFailed < HttpError; end

      cattr_accessor :plural_uri_attributes, :metadata_attributes
      singular_uri_attributes = [
        :logo_uri,
        :client_uri,
        :policy_uri,
        :tos_uri,
        :jwks_uri,
        :sector_identifier_uri,
        :initiate_login_uri
      ]
      singular_attributes = [
        :application_type,
        :client_name,
        :jwks,
        :subject_type,
        :id_token_signed_response_alg,
        :id_token_encrypted_response_alg,
        :id_token_encrypted_response_enc,
        :userinfo_signed_response_alg,
        :userinfo_encrypted_response_alg,
        :userinfo_encrypted_response_enc,
        :request_object_signing_alg,
        :request_object_encryption_alg,
        :request_object_encryption_enc,
        :token_endpoint_auth_method,
        :token_endpoint_auth_signing_alg,
        :default_max_age,
        :require_auth_time
      ] + singular_uri_attributes
      self.plural_uri_attributes = [
        :redirect_uris,
        :request_uris
      ]
      plural_attributes = [
        :response_types,
        :grant_types,
        :contacts,
        :default_acr_values,
      ] + plural_uri_attributes
      self.metadata_attributes = singular_attributes + plural_attributes
      required_metadata_attributes = [
        :redirect_uris
      ]
      attr_required :endpoint
      attr_optional :initial_access_token
      attr_required(*required_metadata_attributes)
      attr_optional(*(metadata_attributes - required_metadata_attributes))

      validates(*required_attributes,   presence: true)
      validates :sector_identifier_uri, presence: {if: :sector_identifier_required?}
      validates(*singular_uri_attributes, url: true, allow_nil: true)
      validate :validate_plural_uri_attributes
      validate :validate_contacts

      def initialize(endpoint, attributes = {})
        self.endpoint = endpoint
        self.initial_access_token = attributes[:initial_access_token]
        self.class.metadata_attributes.each do |_attr_|
          self.send "#{_attr_}=", attributes[_attr_]
        end
      end

      def sector_identifier
        if valid_uri?(sector_identifier_uri)
          URI.parse(sector_identifier_uri).host
        else
          hosts = redirect_uris.collect do |redirect_uri|
            if valid_uri?(redirect_uri, nil)
              URI.parse(redirect_uri).host
            else
              nil
            end
          end.compact.uniq
          if hosts.size == 1
            hosts.first
          else
            nil
          end
        end
      end

      def as_json(options = {})
        validate!
        self.class.metadata_attributes.inject({}) do |hash, _attr_|
          value = self.send _attr_
          hash.merge! _attr_ => value unless value.nil?
          hash
        end
      end

      def register!
        handle_response do
          http_client.post endpoint, to_json, 'Content-Type' => 'application/json'
        end
      end

      def read
        # TODO: Do we want this feature even if we don't have rotate secret nor update metadata support?
      end

      def validate!
        valid? or raise ValidationFailed.new(self)
      end

      private

      def sector_identifier_required?
        subject_type.to_s == 'pairwise' &&
        sector_identifier.blank?
      end

      def valid_uri?(uri, schemes = ['http', 'https'])
        # NOTE: specify nil for schemes to allow any schemes
        URI::regexp(schemes).match(uri).present?
      end

      def validate_contacts
        if contacts
          include_invalid = contacts.any? do |contact|
            begin
              mail = Mail::Address.new(contact)
              mail.address != contact || mail.domain.split(".").length <= 1
            rescue
              :invalid
            end
          end
          errors.add :contacts, 'includes invalid email' if include_invalid
        end
      end

      def validate_plural_uri_attributes
        self.class.plural_uri_attributes.each do |_attr_|
          if (uris = self.send(_attr_))
            include_invalid = uris.any? do |uri|
              !valid_uri?(uri, nil)
            end
            errors.add _attr_, 'includes invalid URL' if include_invalid
          end
        end
      end

      def http_client
        case initial_access_token
        when nil
          OpenIDConnect.http_client
        when Rack::OAuth2::AccessToken::Bearer
          initial_access_token
        else
          Rack::OAuth2::AccessToken::Bearer.new(
            access_token: initial_access_token
          )
        end
      end

      def handle_response
        response = yield
        case response.status
        when 200..201
          handle_success_response response
        else
          handle_error_response response
        end
      end

      def handle_success_response(response)
        credentials = JSON.parse(response.body).with_indifferent_access
        Client.new(
          identifier: credentials[:client_id],
          secret:     credentials[:client_secret],
          expires_in: credentials[:expires_in]
        )
      end

      def handle_error_response(response)
        raise RegistrationFailed.new(response.status, 'Client Registration Failed', response)
      end
    end
  end
end
