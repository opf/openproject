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

# Replaces the runtime generated CostQuery::Filter::CustomField<id> classes with
# a single filter parameterized by the custom field id, in the same way the rest
# of the Queries:: stack handles custom fields.
class Queries::CostReports::Filters::CustomFieldFilter < Queries::CostReports::Filters::CostReportFilter
  KEY = /\Acf_(\d+)\z/

  def self.key
    KEY
  end

  def self.all_for(context = nil)
    available_custom_fields.map { |cf| create!(name: :"cf_#{cf.id}", context:) }
  end

  # Only the formats the engine can generate a join for have a matching
  # CostQuery::Filter::CustomField<id> class.
  def self.available_custom_fields
    WorkPackageCustomField.where(field_format: CostQuery::CustomFieldMixin::SQL_TYPES.keys)
  end

  def custom_field
    return @custom_field if defined?(@custom_field)

    @custom_field = WorkPackageCustomField.find_by(id: custom_field_id)
  end

  def custom_field_id
    name.to_s[KEY, 1]
  end

  def available?
    custom_field.present?
  end

  def human_name
    custom_field&.name.to_s
  end

  def engine_filter
    "CostQuery::Filter::CustomField#{custom_field_id}".constantize
  end

  def type
    case custom_field&.field_format
    when "int"
      :integer
    when "float"
      :float
    when "date"
      :date
    when "string", "text", "link"
      :string
    when "bool"
      :list
    else
      :list_optional
    end
  end

  # The engine filters list custom fields on the option's value rather than its
  # id, because the same expression also aggregates the group.
  def allowed_values
    case custom_field&.field_format
    when "bool"
      [[I18n.t(:general_text_yes), "t"], [I18n.t(:general_text_no), "f"]]
    when "list"
      custom_field.possible_values.map { |option| [option.value, option.value] }
    end
  end
end
