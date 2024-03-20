# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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
  class RowComponent < ::RowComponent
    def name
      content = link_to model.name, edit_ldap_auth_source_path(model)
      if model.seeded_from_env?
        content += helpers.op_icon('icon icon-info2', title: I18n.t(:label_seeded_from_env_warning))
      end

      content
    end

    delegate :host, to: :model

    def users
      model.users.size
    end

    def row_css_id
      "ldap-auth-source-#{model.id}"
    end

    def button_links
      [test_link, delete_link].compact
    end

    def test_link
      link_to t(:button_test), { controller: 'ldap_auth_sources', action: 'test_connection', id: model }
    end

    def delete_link
      return if users > 0

      link_to I18n.t(:button_delete),
              { controller: 'ldap_auth_sources', id: model.id, action: :destroy },
              method: :delete,
              data: { confirm: I18n.t(:text_are_you_sure) },
              class: 'icon icon-delete',
              title: I18n.t(:button_delete)
    end
  end
end
