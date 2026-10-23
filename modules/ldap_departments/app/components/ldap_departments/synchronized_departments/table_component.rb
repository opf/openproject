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
  module SynchronizedDepartments
    class TableComponent < OpPrimer::BorderBoxTableComponent
      columns :group, :dn, :users
      main_column :group
      mobile_columns :group
      mobile_labels :dn, :users

      def mobile_title
        I18n.t("ldap_departments.synchronized_departments.plural")
      end

      def row_class
        RowComponent
      end

      def has_actions?
        true
      end

      def headers
        [
          [:group, { caption: SynchronizedDepartment.human_attribute_name(:group) }],
          [:dn, { caption: SynchronizedDepartment.human_attribute_name(:dn) }],
          [:users, { caption: SynchronizedDepartment.human_attribute_name(:users_count) }]
        ]
      end

      def blank_title
        I18n.t("ldap_departments.synchronized_departments.blankslate.heading")
      end

      def blank_description
        I18n.t("ldap_departments.synchronized_departments.blankslate.description")
      end

      def blank_icon
        :organization
      end

      # The full department path (e.g. "Human Resources / Support"), built in memory from the
      # tree's departments to avoid a hierarchy query per row.
      def path_for(group)
        names = []
        current = group
        while current
          names.unshift(current.name)
          current = groups_by_id[current.parent_id]
        end
        names.join(" / ")
      end

      private

      def groups_by_id
        @groups_by_id ||= rows.filter_map(&:group).index_by(&:id)
      end
    end
  end
end
