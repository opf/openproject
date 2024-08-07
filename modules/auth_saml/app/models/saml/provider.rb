module Saml
  class Provider < ApplicationRecord
    self.table_name = "saml_providers"

    belongs_to :creator, class_name: "User"

    store_attribute :options, :sp_entity_id, :string
    store_attribute :options, :name_identifier_format, :string
    store_attribute :options, :metadata_url, :string
    store_attribute :options, :metadata_xml, :string

    store_attribute :options, :idp_sso_service_url, :string
    store_attribute :options, :idp_slo_service_url, :string

    store_attribute :options, :idp_cert, :string
    store_attribute :options, :idp_cert_fingerprint, :string

    store_attribute :options, :certificate, :string
    store_attribute :options, :private_key, :string
    store_attribute :options, :authn_requests_signed, :boolean
    store_attribute :options, :want_assertions_signed, :boolean
    store_attribute :options, :want_assertions_encrypted, :boolean

    store_attribute :options, :mapping_login, :string
    store_attribute :options, :mapping_mail, :string
    store_attribute :options, :mapping_firstname, :string
    store_attribute :options, :mapping_lastname, :string
    store_attribute :options, :mapping_uid, :string

    store_attribute :options, :requested_login_attribute, :string
    store_attribute :options, :requested_mail_attribute, :string
    store_attribute :options, :requested_firstname_attribute, :string
    store_attribute :options, :requested_lastname_attribute, :string
    store_attribute :options, :requested_uid_attribute, :string

    store_attribute :options, :requested_login_format, :string
    store_attribute :options, :requested_mail_format, :string
    store_attribute :options, :requested_firstname_format, :string
    store_attribute :options, :requested_lastname_format, :string
    store_attribute :options, :requested_uid_format, :string

    attr_accessor :readonly

    validates_presence_of :display_name
    validates_uniqueness_of :display_name

    def slug
      options.fetch(:name) { "saml-#{id}" }
    end

    def limit_self_registration?
      limit_self_registration
    end

    def has_metadata?
      metadata_xml.present? || metadata_url.present?
    end

    def configured?
      sp_entity_id.present? && idp_sso_service_url.present? && certificate_configured?
    end

    def certificate_configured?
      idp_cert.present?
    end

    def assertion_consumer_service_url
      root_url = OpenProject::StaticRouting::StaticUrlHelpers.new.root_url
      URI.join(root_url, "/auth/#{slug}/callback").to_s
    end

    def to_h
      options
        .merge(
          name: slug,
          display_name:,
          assertion_consumer_service_url:,
          check_idp_cert_expiration: true,
          check_sp_cert_expiration: true,
          metadata_signed: certificate.present? && private_key.present?
        )
        .symbolize_keys
    end
  end
end
