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
#

module Documents
  class TableComponent < OpPrimer::BorderBoxTableComponent
    columns :name, :type, :updated_at
    main_column :name
    mobile_columns :name, :updated_at

    options :project

    def row_class
      Documents::RowComponent
    end

    def headers
      [
        [:name, { caption: I18n.t("documents.index_page.name") }],
        [:type, { caption: I18n.t("documents.index_page.type") }],
        [:updated_at, { caption: I18n.t("documents.index_page.updated_at") }]
      ]
    end

    def container_id
      "documents-table"
    end

    def mobile_title
      Document.model_name.human(count: 2)
    end

    def pagination_params
      { params: { action: "index" } }
    end

    def blank_icon
      :briefcase
    end

    def blank_title
      I18n.t("documents.documents_list_blank_slate.heading")
    end

    def render_blank_slate
      render(Primer::Beta::Blankslate.new(border: false, test_selector: "documents-list-blank-slate")) do |component|
        component.with_visual_icon(icon: blank_icon)
        component.with_heading(tag: :h2).with_content(blank_title)

        add_blank_slate_action(component) if can_add_documents?
      end
    end

    private

    def add_blank_slate_action(component)
      component.with_description { I18n.t("documents.documents_list_blank_slate.description") }
      component.with_primary_action(
        scheme: :primary,
        label: I18n.t(:label_document_new),
        tag: :a,
        data: { turbo_method: :post, controller: "disable-when-clicked" },
        href: project_documents_path(project)
      ) do |button|
        button.with_leading_visual_icon(icon: :plus)
        Document.model_name.human
      end
    end

    def can_add_documents?
      User.current.allowed_in_project?(:manage_documents, project)
    end
  end
end
