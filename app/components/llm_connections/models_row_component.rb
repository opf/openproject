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
  # A row of the model catalogue. +model+ here is a raw model card as the server
  # reported it, not an ActiveRecord object.
  class ModelsRowComponent < OpPrimer::BorderBoxRowComponent
    alias_method :card, :model

    def identifier
      render(Primer::Beta::Text.new(font_weight: :bold)) { card["id"] }
    end

    # vLLM and SGLang report the operator's real --max-model-len here, which is
    # more trustworthy than any published figure for the model. Servers that do
    # not report it simply show nothing rather than a guess.
    def context_window
      window = card["max_model_len"]
      return render(Primer::Beta::Text.new(color: :muted)) { "—" } if window.blank?

      number_with_delimiter(window)
    end
  end
end
