require 'net/ldap'
require 'net/ldap/dn'

module LdapGroups
  class SynchronizedFilter < ApplicationRecord
    belongs_to :auth_source

    has_many :groups,
             class_name: '::LdapGroups::SynchronizedGroup',
             foreign_key: 'filter_id',
             dependent: :destroy

    validates_presence_of :filter_string
    validates_presence_of :auth_source
    validate :validate_filter_syntax
    validate :validate_base_dn

    def parsed_filter_string
      Net::LDAP::Filter.from_rfc2254 filter_string
    end

    def used_base_dn
      base_dn.presence || auth_source.base_dn
    end

    private

    def validate_filter_syntax
      parsed_filter_string
    rescue Net::LDAP::FilterSyntaxInvalidError
      errors.add :filter_string, :invalid
    end

    def validate_base_dn
      return unless base_dn.present? && auth_source.present?

      unless base_dn.end_with?(auth_source.base_dn)
        errors.add :base_dn, :must_contain_base_dn
      end
    end
  end
end
