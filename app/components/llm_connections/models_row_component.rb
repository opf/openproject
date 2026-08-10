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

    def source
      if llm_model.manual?
        render(Primer::Beta::Label.new(scheme: :accent)) { I18n.t("admin.llm_connections.models.source_manual") }
      elsif llm_model.withdrawn?
        render(Primer::Beta::Label.new(scheme: :attention)) { I18n.t("admin.llm_connections.models.source_withdrawn") }
      else
        render(Primer::Beta::Label.new(scheme: :secondary)) { I18n.t("admin.llm_connections.models.source_discovered") }
      end
    end

    def button_links
      return [] unless llm_model.manual?

      [
        link_to(helpers.op_icon("icon-delete"),
                url_helpers.llm_model_path(llm_model),
                data: { turbo_method: :delete, turbo_confirm: I18n.t(:text_are_you_sure) },
                title: I18n.t(:button_delete))
      ]
    end
  end
end
