# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

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
