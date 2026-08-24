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

class Queries::LlmModels::Filters::NameFilter < Queries::LlmModels::Filters::LlmModelFilter
  def self.key
    :name
  end

  def type
    :string
  end

  def human_name
    I18n.t("admin.llm_connections.models.filter_label")
  end

  # Matches the identifier the server uses and the friendly name an
  # administrator may have given it, since either is what someone types.
  def where
    escaped = ActiveRecord::Base.sanitize_sql_like(values.first)

    case operator
    when "~", "**"
      ["llm_models.external_id ILIKE :q OR llm_models.display_name ILIKE :q", { q: "%#{escaped}%" }]
    when "!~"
      ["llm_models.external_id NOT ILIKE :q AND (llm_models.display_name IS NULL OR llm_models.display_name NOT ILIKE :q)",
       { q: "%#{escaped}%" }]
    else
      raise "Unsupported operator #{operator}"
    end
  end
end
