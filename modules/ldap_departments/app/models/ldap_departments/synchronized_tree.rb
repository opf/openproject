# frozen_string_literal: true

require "net/ldap"
require "net/ldap/dn"

module LdapDepartments
  # Configuration of an LDAP subtree whose organizational units are mirrored into the OpenProject
  # department hierarchy. The base DN is the anchor: its direct child OUs become top-level
  # departments, deeper OUs are nested accordingly.
  class SynchronizedTree < ApplicationRecord
    belongs_to :ldap_auth_source

    has_many :synchronized_departments,
             class_name: "::LdapDepartments::SynchronizedDepartment",
             inverse_of: :synchronized_tree,
             dependent: :destroy

    validates :name, presence: true
    validates :base_dn, presence: true
    validates :ou_name_attribute, presence: true
    validates :ldap_auth_source, presence: true
    validate :validate_structure_filter_syntax
    validate :validate_user_filter_syntax
    validate :validate_base_dn
    validate :validate_no_overlap

    def parsed_structure_filter
      Net::LDAP::Filter.from_rfc2254 structure_filter_string
    end

    # Filter identifying user (person) entries below the base DN. Falls back to the auth source
    # filter and finally to a generic person filter when nothing is configured.
    def parsed_user_filter
      if user_filter_string.present?
        Net::LDAP::Filter.from_rfc2254 user_filter_string
      elsif ldap_auth_source&.filter_string.present?
        ldap_auth_source.parsed_filter_string
      else
        Net::LDAP::Filter.eq("objectClass", "person")
      end
    end

    def guid_lookup?
      guid_attribute.present?
    end

    private

    def validate_structure_filter_syntax
      parsed_structure_filter
    rescue Net::LDAP::FilterSyntaxInvalidError
      errors.add :structure_filter_string, :invalid
    end

    def validate_user_filter_syntax
      return if user_filter_string.blank?

      Net::LDAP::Filter.from_rfc2254 user_filter_string
    rescue Net::LDAP::FilterSyntaxInvalidError
      errors.add :user_filter_string, :invalid
    end

    def validate_base_dn
      return if base_dn.blank? || ldap_auth_source.blank?

      base = Dn.normalize(base_dn)
      source_base = Dn.normalize(ldap_auth_source.base_dn)

      unless base == source_base || base.end_with?(",#{source_base}")
        errors.add :base_dn, :must_contain_base_dn
      end
    end

    # Two trees on the same auth source may not overlap: neither base DN may be an ancestor of
    # (or identical to) the other, otherwise the same OU would be claimed by both.
    def validate_no_overlap
      return if base_dn.blank? || ldap_auth_source.blank?

      errors.add :base_dn, :overlaps_other_tree if overlapping_sibling?
    end

    def overlapping_sibling?
      mine = Dn.normalize(base_dn)

      SynchronizedTree
        .where(ldap_auth_source_id:)
        .where.not(id: id || 0)
        .any? { |other| dn_overlaps?(mine, Dn.normalize(other.base_dn)) }
    end

    def dn_overlaps?(one, other)
      one == other || one.end_with?(",#{other}") || other.end_with?(",#{one}")
    end
  end
end
