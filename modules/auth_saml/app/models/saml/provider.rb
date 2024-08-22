module Saml
  class Provider < AuthProvider
    include HashBuilder

    store_attribute :options, :icon, :string
    store_attribute :options, :sp_entity_id, :string
    store_attribute :options, :name_identifier_format, :string
    store_attribute :options, :metadata_url, :string
    store_attribute :options, :metadata_xml, :string
    store_attribute :options, :last_metadata_update, :datetime

    store_attribute :options, :idp_sso_service_url, :string
    store_attribute :options, :idp_slo_service_url, :string

    store_attribute :options, :idp_cert, :string
    # Allow fallbcak to fingerprint from previous versions,
    # but we do not offer this in the UI
    store_attribute :options, :idp_cert_fingerprint, :string

    store_attribute :options, :certificate, :string
    store_attribute :options, :private_key, :string
    store_attribute :options, :authn_requests_signed, :boolean
    store_attribute :options, :want_assertions_signed, :boolean
    store_attribute :options, :want_assertions_encrypted, :boolean
    store_attribute :options, :digest_method, :string
    store_attribute :options, :signature_method, :string

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

    def self.slug_fragment = "saml"

    def seeded_from_env?
      (Setting.seed_saml_provider || {}).key?(slug)
    end

    def has_metadata?
      metadata_xml.present? || metadata_url.present?
    end

    def metadata_updated?
      metadata_xml_changed? || metadata_url_changed?
    end

    def metadata_endpoint
      URI.join(auth_url, "metadata").to_s
    end

    def configured?
      sp_entity_id.present? &&
        idp_sso_service_url.present? &&
        idp_certificate_configured?
    end

    def mapping_configured?
      mapping_login.present? &&
        mapping_mail.present? &&
        mapping_firstname.present? &&
        mapping_lastname.present?
    end

    def loaded_certificate
      return nil if certificate.blank?

      @loaded_certificate ||= OpenSSL::X509::Certificate.new(certificate)
    end

    def loaded_private_key
      return nil if private_key.blank?

      @loaded_private_key ||= OpenSSL::PKey::RSA.new(private_key)
    end

    def loaded_idp_certificates
      return nil if idp_cert.blank?

      @loaded_idp_certificates ||= OpenSSL::X509::Certificate.load(idp_cert)
    end

    def idp_certificate_configured?
      idp_cert.present?
    end

    def idp_certificate_valid?
      return false if idp_cert.blank?

      !loaded_idp_certificates.all? { |cert| OneLogin::RubySaml::Utils.is_cert_expired(cert) }
    end

    def idp_cert=(cert)
      formatted =
        if cert.nil? || cert.include?("BEGIN CERTIFICATE")
          cert
        else
          OneLogin::RubySaml::Utils.format_cert(cert)
        end

      super(formatted)
    end

    def assertion_consumer_service_url
      callback_url
    end
  end
end
