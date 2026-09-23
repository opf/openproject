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

    def column_css_class(column)
      return "#{super} -no-ellipsis" if column == :source

      super
    end

    def identifier
      render(Primer::Beta::Truncate.new(font_weight: :bold)) do |truncate|
        truncate.with_item(expandable: true, max_width: 320, title: llm_model.name) { llm_model.name }
      end
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
    # that produces vectors is an embedding model, and everything else is a chat
    # model.
    def kind
      if table.embeddings_states[llm_model.external_id] == "supported"
        render(Primer::Beta::Label.new(scheme: :success)) { I18n.t("llm.model_kinds.embedding") }
      else
        render(Primer::Beta::Label.new(scheme: :secondary)) { I18n.t("llm.model_kinds.chat") }
      end
    end

    def source
      scheme, key = source_label

      render(Primer::Beta::Label.new(scheme:, title: I18n.t("admin.llm_models.index.#{key}_description"))) do
        I18n.t("admin.llm_models.index.#{key}")
      end
    end

    def source_label
      return %i[accent source_manual] if llm_model.manual?
      return %i[attention source_withdrawn] if llm_model.withdrawn?

      %i[secondary source_discovered]
    end

    def button_links
      llm_model.manual? ? [edit_link, delete_link] : [edit_link]
    end

    # The classes belong on the anchor, not on an inner <i>: ".icon:before"
    # carries the padding and colour, and "a.icon:hover" is what suppresses the
    # underline. Split across two elements the row gets neither.
    def edit_link
      icon_link_to(url_helpers.edit_llm_model_path(llm_model),
                   icon: "icon-edit",
                   label: I18n.t(:button_edit),
                   data: { test_selector: "llm-model--edit-#{llm_model.id}" })
    end

    # Opens a DangerDialog rather than a browser confirm, so the message can say
    # which features are bound to the model.
    def delete_link
      icon_link_to(url_helpers.delete_dialog_llm_model_path(llm_model),
                   icon: "icon-delete",
                   label: I18n.t(:button_delete),
                   data: { controller: "async-dialog", test_selector: "llm-model--delete-#{llm_model.id}" })
    end

    # The glyph comes from the ":before" of the icon class, so the anchor has no
    # text of its own and needs the label spelled out for a screen reader.
    def icon_link_to(path, icon:, label:, data:)
      link_to(path, class: "icon #{icon}", title: label, data:) do
        content_tag(:span, label, class: "sr-only")
      end
    end
  end
end
