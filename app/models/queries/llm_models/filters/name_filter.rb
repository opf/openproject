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
    I18n.t("admin.llm_models.index.filter_label")
  end

  # Matches the identifier the server uses and the friendly name an
  # administrator may have given it, since either is what someone types.
  #
  # Every operator the :string strategy allows has a branch. BaseQuery applies
  # filters without asking whether they are valid, so a missing one is a 500 on
  # a hand-written filter parameter rather than a validation error.
  def where
    return "1=0" if values.first.blank?

    case operator
    when "~" then contains
    when "!~" then excludes_substring
    when "=" then equals
    when "!" then differs
    end
  end

  private

  def term = ActiveRecord::Base.sanitize_sql_like(values.first)

  def contains
    ["llm_models.external_id ILIKE :q OR llm_models.display_name ILIKE :q", { q: "%#{term}%" }]
  end

  def excludes_substring
    ["llm_models.external_id NOT ILIKE :q AND (llm_models.display_name IS NULL OR llm_models.display_name NOT ILIKE :q)",
     { q: "%#{term}%" }]
  end

  def equals
    ["llm_models.external_id = :q OR llm_models.display_name = :q", { q: values.first }]
  end

  def differs
    ["llm_models.external_id <> :q AND (llm_models.display_name IS NULL OR llm_models.display_name <> :q)",
     { q: values.first }]
  end
end
