module Saml
  module Provider::HashBuilder
    def formatted_attribute_statements
      {
        email: split_attribute_mapping(mapping_mail),
        login: split_attribute_mapping(mapping_login),
        first_name: split_attribute_mapping(mapping_firstname),
        last_name: split_attribute_mapping(mapping_lastname),
        uid: split_attribute_mapping(mapping_uid)
      }.compact
    end

    def split_attribute_mapping(mapping)
      return if mapping.blank?

      mapping.split(/\s*\R+\s*/)
    end

    def formatted_request_attributes
      [
        { name: requested_login_attribute, name_format: requested_login_format, friendly_name: "Login" },
        { name: requested_mail_attribute, name_format: requested_mail_format, friendly_name: "Email" },
        { name: requested_firstname_attribute, name_format: requested_firstname_format, friendly_name: "First Name" },
        { name: requested_lastname_attribute, name_format: requested_lastname_format, friendly_name: "Last Name" }
      ]
    end

    def idp_cert_options_hash
      if idp_cert_fingerprint.present?
        return { idp_cert_fingerprint: }
      end

      if idp_cert.present?
        certificates = loaded_idp_certificates.map(&:to_pem)
        if certificates.count > 1
          {
            idp_cert_multi: {
              signing: certificates,
              encryption: certificates
            }
          }
        else
          { idp_cert: certificates.first }
        end
      else
        {}
      end
    end

    def security_options_hash
      {
        check_idp_cert_expiration: false, # done in contract
        check_sp_cert_expiration: false, # done in contract
        metadata_signed: certificate.present? && private_key.present?,
        authn_requests_signed: !!authn_requests_signed,
        want_assertions_signed: !!want_assertions_signed,
        want_assertions_encrypted: !!want_assertions_encrypted,
        digest_method:,
        signature_method:
      }.compact
    end

    def to_h # rubocop:disable Metrics/AbcSize
      {
        name: slug,
        display_name:,
        icon:,
        assertion_consumer_service_url:,
        sp_entity_id:,
        idp_sso_service_url:,
        idp_slo_service_url:,
        name_identifier_format:,
        certificate:,
        private_key:,
        attribute_statements: formatted_attribute_statements,
        request_attributes: formatted_request_attributes,
        uid_attribute: mapping_uid
      }
        .merge(idp_cert_options_hash)
        .merge(security: security_options_hash)
        .compact
    end
  end
end
