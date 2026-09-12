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

module LlmConnections
  # A row of the model list. Note +model+ is the row's record (an LlmModel),
  # not the connection -- aliased to avoid confusion with either.
  class ModelsRowComponent < OpPrimer::BorderBoxRowComponent
    alias_method :llm_model, :model

    def identifier
      render(Primer::Beta::Text.new(font_weight: :bold)) { llm_model.name }
    end

    # vLLM and SGLang report the operator's real --max-model-len here, which is
    # more trustworthy than any published figure for the model. Servers that do
    # not report it simply show nothing rather than a guess.
    def context_window
      window = llm_model.context_window
      return render(Primer::Beta::Text.new(color: :muted)) { "—" } if window.blank?

      number_with_delimiter(window)
    end

    # Derived from the embeddings verdict rather than stored separately: a model
    # that produces vectors is an embedding model, and that is the same fact.
    def kind
      case table.embeddings_states[llm_model.external_id]
      when "supported"
        render(Primer::Beta::Label.new(scheme: :success)) { I18n.t("llm.model_kinds.embedding") }
      when "unsupported"
        render(Primer::Beta::Label.new(scheme: :secondary)) { I18n.t("llm.model_kinds.chat") }
      else
        render(Primer::Beta::Label.new(scheme: :secondary, inline: true)) { I18n.t("llm.model_kinds.unknown") }
      end
    end

    def source
      scheme, key = source_label

      render(Primer::Beta::Label.new(scheme:)) { I18n.t("admin.llm_connections.models.#{key}") }
    end

    def source_label
      # Withdrawn wins over hidden: the withdrawal is why the toggle is inert,
      # and an administrator needs that explanation more than their own choice.
      return %i[attention source_withdrawn] if llm_model.withdrawn?
      return %i[attention source_deactivated] if llm_model.deactivated?
      return %i[accent source_manual] if llm_model.manual?

      %i[secondary source_discovered]
    end

    # Whether a feature may choose this model. A withdrawn model has nothing to
    # switch on -- the server stopped offering it -- so its toggle is inert
    # rather than absent, which keeps the column aligned and says why.
    def status
      render(Primer::Alpha::ToggleSwitch.new(**toggle_options))
    end

    def toggle_options
      options = {
        checked: llm_model.selectable?,
        enabled: togglable?,
        size: :small,
        # A bare ToggleSwitch has no accessible name, and axe fails without one.
        aria: { label: I18n.t("admin.llm_connections.models.toggle_aria_label", model: llm_model.name) },
        test_selector: "llm-model--toggle-#{llm_model.id}"
      }

      togglable? ? options.merge(mutation_options) : options
    end

    def mutation_options
      {
        src: url_helpers.toggle_llm_model_path(llm_model),
        csrf_token: helpers.form_authenticity_token,
        data: { "turbo-method": :post, "turbo-stream": true },
        classes: "op-primer-adjustments__toggle-switch--hidden-loading-indicator"
      }
    end

    def togglable? = llm_model.active?

    def button_links
      llm_model.manual? ? [edit_link, delete_link] : [edit_link]
    end

    def edit_link
      link_to(helpers.op_icon("icon-edit"),
              url_helpers.edit_llm_model_path(llm_model),
              data: { test_selector: "llm-model--edit-#{llm_model.id}" },
              title: I18n.t(:button_edit))
    end

    # Opens a DangerDialog rather than a browser confirm, so the message can say
    # which features are bound to the model.
    def delete_link
      link_to(helpers.op_icon("icon-delete"),
              url_helpers.delete_dialog_llm_model_path(llm_model),
              data: { controller: "async-dialog", test_selector: "llm-model--delete-#{llm_model.id}" },
              title: I18n.t(:button_delete))
    end
  end
end
