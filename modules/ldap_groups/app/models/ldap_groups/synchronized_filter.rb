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

    def parsed_filter_string
      Net::LDAP::Filter.from_rfc2254 filter_string
    end

    private

    def validate_filter_syntax
      parsed_filter_string
    rescue Net::LDAP::FilterSyntaxInvalidError
      errors.add :filter_string, :invalid
    end
  end
end
