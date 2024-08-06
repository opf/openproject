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

# Purpose: Defines the row model for the table of Storage objects
# Used by: Storages table in table_component.rb
module Storages::Admin
  class RowComponent < ::RowComponent
    def storage
      row
    end

    # Delegate delegates the execution of certain methods to :storage.
    # https://www.rubydoc.info/gems/activesupport/Module:delegate
    delegate :created_at, :host, :provider_type, :configured?, to: :storage

    def row_css_id
      helpers.dom_id storage
    end

    def name
      if configured?
        storage.name
      else
        render(Primer::Beta::Octicon.new(:"alert-fill", size: :small, color: :severe)) +
          content_tag(:span,
                      storage.name,
                      class: "pl-2")
      end
    end

    def creator
      icon = helpers.avatar storage.creator, size: :mini
      icon + storage.creator.name
    end

    def button_links
      [edit_link, delete_link]
    end

    def delete_link
      link_to "",
              admin_settings_storage_path(storage),
              class: "icon icon-delete",
              data: { confirm: I18n.t("storages.delete_warning.storage") },
              title: I18n.t(:button_delete),
              method: :delete
    end

    def edit_link
      link_to "",
              edit_admin_settings_storage_path(storage),
              class: "icon icon-edit",
              accesskey: helpers.accesskey(:edit),
              title: I18n.t(:button_edit)
    end
  end
end
