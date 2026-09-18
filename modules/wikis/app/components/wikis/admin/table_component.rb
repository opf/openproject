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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Wikis::Admin
  class TableComponent < OpPrimer::BorderBoxTableComponent
    columns :name, :provider_type, :created_at
    main_column :name
    mobile_columns :name

    def row_class
      ::Wikis::Admin::RowComponent
    end

    def headers
      [
        [:name, { caption: I18n.t("wikis.admin.wiki_provider_list_component.label_name") }],
        [:provider_type, { caption: I18n.t("wikis.admin.wiki_provider_list_component.label_provider") }],
        [:created_at, { caption: I18n.t("wikis.admin.wiki_provider_list_component.label_creation_time") }]
      ]
    end

    def container_id
      "wiki-providers-table"
    end

    def mobile_title
      I18n.t("menus.admin.external_wiki_providers")
    end

    def blank_icon
      :browser
    end

    def blank_title
      I18n.t("wikis.admin.wiki_provider_list_component.no_results_title")
    end

    def blank_description
      I18n.t("wikis.admin.wiki_provider_list_component.no_results_description")
    end

    def render_blank_slate
      render(Primer::Beta::Blankslate.new(border: false, test_selector: "wiki-providers-blank-slate")) do |component|
        component.with_visual_icon(icon: blank_icon)
        component.with_heading(tag: :h2).with_content(blank_title)
        component.with_description { blank_description }
      end
    end
  end
end
