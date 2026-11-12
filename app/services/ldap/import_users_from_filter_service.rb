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

module Ldap
  class ImportUsersFromFilterService < BaseService
    attr_reader :filter

    def initialize(ldap, filter)
      super(ldap)
      @filter = filter
    end

    def perform
      get_entries_from_filter do |entry|
        attributes = ldap.get_user_attributes_from_ldap_entry(entry)
        next if User.by_login(attributes[:login]).exists?

        try_to_create attributes.except(:dn)
      end
    end

    def get_entries_from_filter(&)
      ldap_con = new_ldap_connection

      ldap_con.search(
        base: ldap.base_dn,
        filter: filter & ldap.default_filter,
        attributes: ldap.search_attributes,
        &
      )
    end
  end
end
