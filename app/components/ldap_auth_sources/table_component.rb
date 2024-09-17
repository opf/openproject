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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module LdapAuthSources
  class TableComponent < ::TableComponent
    columns :name, :host, :users

    def initial_sort
      %i[id asc]
    end

    def sortable?
      true
    end

    def sortable_column?(_column)
      false
    end

    def inline_create_link
      link_to(new_ldap_auth_source_path,
              class: "budget-add-row wp-inline-create--add-link",
              title: I18n.t(:label_ldap_auth_source_new)) do
        helpers.op_icon("icon icon-add")
      end
    end

    def headers
      [
        ["name", { caption: LdapAuthSource.human_attribute_name("name") }],
        ["host", { caption: LdapAuthSource.human_attribute_name("host") }],
        ["users", { caption: I18n.t(:label_user_plural) }]
      ]
    end
  end
end
