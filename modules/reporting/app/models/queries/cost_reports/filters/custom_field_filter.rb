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

  def self.all_available
    return [] unless CustomField.can_be_used_as_a_filter?

    available_custom_fields.map { |cf| create!(name: :"cf_#{cf.id}") }
  end

  def self.available_custom_fields
    WorkPackageCustomField.filterable
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

  def allowed_values
    return nil unless custom_field&.list?

    custom_field.custom_options.pluck(:value, :id).map { |value, id| [value, id.to_s] }
  end
end
