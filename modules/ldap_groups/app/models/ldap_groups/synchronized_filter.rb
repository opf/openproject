require "net/ldap"
require "net/ldap/dn"

module LdapGroups
  class SynchronizedFilter < ApplicationRecord
    belongs_to :ldap_auth_source

    has_many :groups,
             class_name: "::LdapGroups::SynchronizedGroup",
             foreign_key: "filter_id",
             dependent: :destroy

    validates_presence_of :name
    validates_presence_of :filter_string
    validates_presence_of :ldap_auth_source
    validate :validate_filter_syntax
    validate :validate_base_dn

    def parsed_filter_string
      Net::LDAP::Filter.from_rfc2254 filter_string
    end

    def used_base_dn
      base_dn.presence || ldap_auth_source.base_dn
    end

    def seeded_from_env?
      return false if ldap_auth_source.nil?

      ldap_auth_source&.seeded_from_env? &&
        Setting.seed_ldap.dig(ldap_auth_source.name, "groupfilter", name)
    end

    private

    def validate_filter_syntax
      parsed_filter_string
    rescue Net::LDAP::FilterSyntaxInvalidError
      errors.add :filter_string, :invalid
    end

    def validate_base_dn
      return unless base_dn.present? && ldap_auth_source.present?

      unless base_dn.end_with?(ldap_auth_source.base_dn)
        errors.add :base_dn, :must_contain_base_dn
      end
    end
  end
end
