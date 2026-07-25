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

      # LiveComponent::Base::Overrides#render_in is prepended by `include
      # LiveComponent::Base` above, and it unconditionally serializes the
      # full props (document attributes included) into the `data-state` HTML
      # attribute before ViewComponent's `render?` is ever consulted -- so a
      # bare `render?` guard suppresses only the visible markup, not that
      # serialized payload. Prepending a module *after* the include puts it
      # above Overrides in the ancestor chain, so it runs first and can
      # short-circuit the entire render -- including `data-state` -- before
      # Overrides ever serializes anything.
      #
      # IMPORTANT: this guards *rendering only*. LiveComponent::RenderComponent
      # dispatches every client-named reflex BEFORE it calls
      # `component.render_in` (see its #render_in), so RenderGuard cannot gate
      # a reflex. Reflexes must authorize themselves -- see #update_title.
      module RenderGuard
        def render_in(view_context, &)
          return "".html_safe unless render?

          super
        end
      end
      prepend RenderGuard

      STATES = %i[show edit].freeze
      DOM_ID = "document-page-header-live"

      # The gem derives tag/controller names from JS sidecar files, which
      # OpenProject does not use (controllers live under frontend/src); pin
      # both so the custom element and Stimulus identifier match the manual
      # JS registration.
      LC_IDENTIFIER = "documents-showeditview-pageheadercomponent"

      # `attributes: false` matters twice over: with `reload: true` the
      # deserialized attribute hash is discarded anyway (ModelSerializer
      # re-locates from the database), and the default `attributes: true`
      # would dump every column of the record into the `data-state` attribute
      # of the served page.
      serializes :document, with: :model_serializer, reload: true, attributes: false

      attr_reader :document, :state

      def self.__lc_controller = LC_IDENTIFIER

      # Derived, never a prop. An independently deserialized `project:` would
      # be authorized by nothing -- `render?` guards the document, so a
      # mismatched (document, project) pair would leak the foreign project's
      # name and identifier through the breadcrumbs and evaluate
      # `manage_documents` against a project of the client's choosing.
      delegate :project, to: :document

      # The render endpoint (LiveComponentsController) performs no record-level
      # authorization of its own and the client names the record to render, so
      # the component must enforce read permission itself. See the controller's
      # ALLOWED_COMPONENTS comment and DREAM-784.
      #
      # The type check is not redundant: a GlobalID names its own model class,
      # so the client picks what `document` actually is. Several models answer
      # `#project` and `#title`, and without this the render only fails later,
      # by accident, at the first Document-specific method call.
      def render?
        document.is_a?(Document) &&
          User.current.allowed_in_project?(:view_documents, document.project)
      end

      def initialize(document:, state: :show)
        super()
        @document = document
        # `to_s` first: `state` arrives from client-controlled props and is not
        # necessarily a Symbol or String (`to_sym` on a Hash or Integer would
        # raise NoMethodError and surface as a 500).
        @state = state.to_s.to_sym.presence_in(STATES) || :show
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

      # Reflex: invoked from the client via SafeDispatcher before re-render
      # (see LiveComponent::RenderComponent#render_in). Public on purpose --
      # that is the dispatch contract, so this method authorizes itself
      # rather than relying on the render endpoint (which performs no
      # authorization -- see LiveComponentsController).
      #
      # `render?` is repeated here deliberately: reflexes are dispatched
      # before RenderGuard runs, so a reflex is reachable on a document the
      # caller may not even read. Authorizing the read here as well as the
      # write keeps that from being the contract's problem to catch.
      def update_title(title:)
        return unless render?
        return unless allowed_to_manage_documents?
        return unless title.is_a?(String)

        call = Documents::UpdateService
          .new(user: User.current, model: document)
          .call(title:)

        @document = call.result
        @state = call.success? ? :show : :edit
      end

      private

      def __lc_tag_name = LC_IDENTIFIER

      def render_title_edit_form
        safe_join([title_edit_error_banner, title_edit_form])
      end

      def title_edit_error_banner
        return unless document.errors.any?

        render(Primer::Alpha::Banner.new(scheme: :danger, mb: 2)) { document.errors.full_messages.to_sentence }
      end

      def title_edit_form
        # url: "#" is a harmless no-JS fallback (a GET to the current page) --
        # submission is normally intercepted by the Stimulus #save action
        # before it ever hits the network. There is no real route to point
        # this at (saving goes through the reflex, not a controller action),
        # so don't "fix" this into one.
        form_with(model: document, url: "#",
                  class: "d-flex",
                  data: { action: "#{self.class.__lc_controller}#save" }) do |f|
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
        render(Primer::Beta::Button.new(type: :button, ml: 2, data: { action: cancel_action })) { I18n.t("button_cancel") }
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
