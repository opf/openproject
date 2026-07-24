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
      include LiveComponent::Base

      STATES = %i[show edit].freeze
      DOM_ID = "document-page-header-live"

      # The gem derives tag/controller names from JS sidecar files, which
      # OpenProject does not use (controllers live under frontend/src); pin
      # both so the custom element and Stimulus identifier match the manual
      # JS registration.
      LC_IDENTIFIER = "documents-showeditview-pageheadercomponent"

      serializes :document, with: :model_serializer, reload: true
      serializes :project, with: :model_serializer, reload: true

      attr_reader :document, :project, :state

      def self.__lc_controller = LC_IDENTIFIER

      def initialize(document:, project:, state: :show)
        super()
        @document = document
        @project = project
        @state = state.to_sym.presence_in(STATES) || :show
      end

      # A client-requested :edit without manage_documents permission
      # renders as :show instead of raising. See #page_header_attributes
      # for why this is also the only state ever forwarded to Primer's
      # PageHeader/Title.
      def display_state
        state == :edit && !allowed_to_manage_documents? ? :show : state
      end

      def page_header_attributes
        {
          test_selector: "document-page-header",
          # Always :show: Primer::OpenProject::PageHeader::Title#render?
          # raises unless state is :show or its editable_form slot is
          # populated, and that slot only knows how to build a
          # server-round-trip form (fixed update_path/cancel_path). We
          # don't use that slot -- the edit form is rendered as ordinary
          # title content instead (see #render_title_edit_form) -- so
          # Title must never see anything but :show.
          state: :show
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

      def render_title_edit_form
        safe_join([title_edit_error_banner, title_edit_form])
      end

      private

      def __lc_tag_name = LC_IDENTIFIER

      def title_edit_error_banner
        return unless document.errors.any?

        render(Primer::Alpha::Banner.new(scheme: :danger, mb: 2)) { document.errors.full_messages.to_sentence }
      end

      def title_edit_form
        form_with(model: document, url: update_title_document_path(document), method: :put,
                  class: "d-flex") do |f|
          safe_join([title_edit_input(f), title_edit_save_button, title_edit_cancel_button])
        end
      end

      def title_edit_input(form)
        form.text_field(:title,
                        id: "document_title",
                        required: false,
                        value: document.title,
                        "aria-label": Document.human_attribute_name(:title),
                        data: { "#{self.class.__lc_controller}_target": "titleInput" })
      end

      def title_edit_save_button
        render(Primer::Beta::Button.new(type: :submit, scheme: :primary, ml: 2)) { I18n.t("button_save") }
      end

      def title_edit_cancel_button
        cancel_action = "#{self.class.__lc_controller}#cancel"
        render(Primer::Beta::Button.new(type: :button, ml: 2, data: { action: cancel_action })) { I18n.t(:button_cancel) }
      end

      def breadcrumbs_items
        [{ href: project_overview_path(project.id), text: project.name },
         { href: project_documents_path(project), text: I18n.t(:label_document_plural) },
         document.title]
      end

      def allowed_to_manage_documents?
        User.current.allowed_in_project?(:manage_documents, project)
      end
    end
  end
end
