# frozen_string_literal: true

module LdapDepartments
  # Helpers for working with LDAP distinguished names. Parsing is delegated to Net::LDAP::DN,
  # which respects some of the weirder parsing and escaping rules.
  module Dn
    module_function

    # Number of key-value parts (RDN) in the DN. Used to find and process shallower OUs first.
    def depth(value)
      parse(value).size
    end

    # Normalized form for case- and escaping-insensitive comparison. Values are decoded by the parser
    # and then re-escaped, in case there are differing encodings.
    # The result is itself a valid DN, which ensures this method is idempotent.
    def normalize(value)
      canonical(parse(value))
    end

    # The parent DN (everything except the first RDN) in canonical form
    # returns nil for a single-component DN.
    def parent(value)
      rdns = parse(value)
      return nil if rdns.size <= 1

      canonical(rdns.drop(1))
    end

    # Parsed RDNs as [attribute, value] pairs with values already decoded. A malformed DN returns an
    # empty array so a single bad entry is skipped rather than aborting the whole synchronization.
    def parse(value)
      return [] if value.blank?

      Net::LDAP::DN.new(value.to_s).to_a.each_slice(2).to_a
    rescue Net::LDAP::InvalidDNError
      []
    end

    def canonical(rdns)
      rdns
        .map { |attribute, attribute_value| "#{attribute.downcase}=#{Net::LDAP::DN.escape(attribute_value.strip).downcase}" }
        .join(",")
    end
  end
end
