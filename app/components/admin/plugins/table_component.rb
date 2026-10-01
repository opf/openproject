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

module Admin
  module Plugins
    class TableComponent < OpPrimer::BorderBoxTableComponent
      columns :name, :author, :version
      main_column :name

      def row_class
        RowComponent
      end

      def headers
        [
          [:name, { caption: I18n.t("label_name") }],
          [:author, { caption: I18n.t("attributes.author") }],
          [:version, { caption: I18n.t("attributes.version") }]
        ]
      end

      def container_id
        "admin-plugins-table"
      end

      def mobile_title
        I18n.t(:label_plugins)
      end

      def blank_icon
        :package
      end

      def blank_title
        I18n.t("admin.plugins.no_results_title_text")
      end

      def blank_description
        render(Primer::Beta::Link.new(href: OpenProject::Static::Links.url_for(:integrations))) do
          I18n.t("admin.plugins.no_results_content_text")
        end
      end
    end
  end
end
