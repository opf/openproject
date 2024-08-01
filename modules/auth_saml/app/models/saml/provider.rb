module Saml
  class Provider < ApplicationRecord
    self.table_name = "saml_providers"

    DEFAULT_NAME_IDENTIFIER_FORMAT = 'urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress'.freeze
    DEFAULT_MAIL_MAPPING = %w[mail email Email emailAddress emailaddress
      urn:oid:0.9.2342.19200300.100.1.3 http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress].freeze

    DEFAULT_FIRSTNAME_MAPPING = %w[givenName givenname given_name given_name
      urn:oid:2.5.4.42 http://schemas.xmlsoap.org/ws/2005/05/identity/claims/givenname].freeze

    DEFAULT_LASTNAME_MAPPING = %w[surname sur_name sn
      urn:oid:2.5.4.4 http://schemas.xmlsoap.org/ws/2005/05/identity/claims/surname].freeze

    DEFAULT_REQUESTED_ATTRIBUTES = [
      {
        "name" => "mail",
        "name_format" => "urn:oasis:names:tc:SAML:2.0:attrname-format:basic",
        "friendly_name" => "Email address",
        "is_required" => true
      },
      {
        "name" => "givenName",
        "name_format" => "urn:oasis:names:tc:SAML:2.0:attrname-format:basic",
        "friendly_name" => "Given name",
        "is_required" => true
      },
      {
        "name" => "sn",
        "name_format" => "urn:oasis:names:tc:SAML:2.0:attrname-format:basic",
        "friendly_name" => "Family name",
        "is_required" => true
      }
    ].freeze

    store_attribute :options, :sp_entity_id, :string, default: -> { OpenProject::StaticRouting::StaticUrlHelpers.new.root_url }
    store_attribute :options, :name_identifier_format, :string, default: -> { DEFAULT_NAME_IDENTIFIER_FORMAT }
    store_attribute :options, :metadata_url, :string
    store_attribute :options, :metadata_xml, :string

    store_attribute :options, :mapping_login, :json, default: -> { DEFAULT_MAIL_MAPPING }
    store_attribute :options, :mapping_mail, :json, default: -> { DEFAULT_MAIL_MAPPING }
    store_attribute :options, :mapping_firstname, :json, default: -> { DEFAULT_FIRSTNAME_MAPPING }
    store_attribute :options, :mapping_lastname, :json, default: -> { DEFAULT_LASTNAME_MAPPING }
    store_attribute :options, :mapping_uid, :json

    store_attribute :options, :request_attributes, :json, default: -> { DEFAULT_REQUESTED_ATTRIBUTES }

    attr_accessor :readonly
    validates_presence_of :display_name

    def slug
      "saml-#{id}"
    end

    def assertion_consumer_service_url
      URI.join(url_helpers.root_url, "/auth/#{name}/callback").to_s
    end

    def limit_self_registration?
      limit_self_registration
    end

    def to_h
      options
        .merge(
          name: slug,
          display_name:,
          assertion_consumer_service_url:,
        )
    end

    private

  end
end
