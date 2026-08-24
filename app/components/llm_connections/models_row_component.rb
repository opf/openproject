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
      return %i[accent source_manual] if llm_model.manual?
      return %i[attention source_withdrawn] if llm_model.withdrawn?

      %i[secondary source_discovered]
    end
  end
end
