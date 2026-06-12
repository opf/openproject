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
  module ShowEditView
    class PageHeaderComponent < ApplicationComponent
      include OpTurbo::Streamable

      alias_method :document, :model

      options :project
      options state: :show
      options version_journal: nil

      def page_header_attributes
        {
          test_selector: "document-page-header",
          state:,
          data: {
            controller: "editable-page-header-title",
            "editable-page-header-title-input-id-value": "document_title"
          }
        }
      end

      def action_menu_options
        {
          menu_arguments: { anchor_align: :end },
          button_arguments: {
            icon: "kebab-horizontal",
            "aria-label": t("documents.page_header.action_menu.document_actions")
          }
        }
      end

      private

      def breadcrumbs_items
        [{ href: project_overview_path(project.id), text: project.name },
         { href: project_documents_path(project), text: I18n.t(:label_document_plural) },
         document.title]
      end

      def allowed_to_manage_documents?
        version_journal.nil? && User.current.allowed_in_project?(:manage_documents, project)
      end
    end
  end
end
