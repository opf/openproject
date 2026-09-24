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

class Queries::Workflows::Filters::NameFilter < Queries::Workflows::Filters::WorkflowFilter
  COLUMNS = ["workflows.name",
             "COALESCE(workflows.description, '')"].freeze

  def type
    :string
  end

  def human_name
    I18n.t("workflows.index.filters.name")
  end

  def self.key
    :name
  end

  def where
    case operator
    when "~", "**"
      where_contains
    when "!~"
      where_not(where_contains)
    when "="
      where_equal
    when "!"
      where_not(where_equal)
    end
  end

  private

  def where_contains
    match(COLUMNS.map { |column| "LOWER(#{column}) LIKE ?" }) { |value| "%#{value.downcase}%" }
  end

  def where_equal
    match(COLUMNS.map { |column| "LOWER(#{column}) = ?" }, &:downcase)
  end

  def match(conditions)
    joined = []
    assignments = []

    values.each do |value|
      joined << conditions.join(" OR ")
      assignments += Array.new(conditions.size) { yield(value) }
    end

    ["(#{joined.join(') OR (')})", *assignments]
  end

  def where_not(condition)
    ["NOT(#{condition.first})", *condition.drop(1)]
  end
end
