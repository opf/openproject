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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

class Queries::WorkPackageCustomFields::Filters::ProjectValuesFilter <
  Queries::WorkPackageCustomFields::Filters::WorkPackageCustomFieldFilter
  def self.key
    :project_values
  end

  def type
    :empty_value
  end

  def human_name
    I18n.t("projects.settings.custom_fields.values_filter")
  end

  def available_operators
    [
      ::Queries::Operators::WorkPackageCustomFields::All,
      ::Queries::Operators::WorkPackageCustomFields::Customizable,
      ::Queries::Operators::WorkPackageCustomFields::Customized,
      ::Queries::Operators::WorkPackageCustomFields::Uniform
    ]
  end

  def default_operator
    ::Queries::Operators::WorkPackageCustomFields::All
  end

  def where
    case operator
    when "customizable" then customizable_condition
    when "customized" then customized_condition
    when "uniform" then "NOT (#{customized_condition})"
    end
  end

  private

  def operator_strategy
    available_operators.find { |available| available.symbol == operator }
  end

  def customizable_condition
    <<~SQL.squish
      custom_fields.settings @> '{"project_level_value_management": true}'
      OR custom_fields.settings @> '{"allow_additional_project_values": true}'
    SQL
  end

  def customized_condition
    <<~SQL.squish
      custom_fields.id IN (#{CustomOption.where(project_id: project.id).select(:custom_field_id).to_sql})
      OR custom_fields.id IN (#{fields_with_project_items.to_sql})
      OR EXISTS (#{project_restrictions.to_sql})
    SQL
  end

  def fields_with_project_items
    project_item_ids = CustomField::Hierarchy::Item.where(project_id: project.id).select(:id)
    ancestor_ids = CustomField::Hierarchy::ItemHierarchy.where(descendant_id: project_item_ids).select(:ancestor_id)

    CustomField::Hierarchy::Item.where(id: ancestor_ids, parent_id: nil).select(:custom_field_id)
  end

  def project_restrictions
    restrictions = CustomField::ProjectSpecificValueRestriction.table_name

    CustomField::ProjectSpecificValueRestriction
      .where(project_id: project.id)
      .where("#{restrictions}.custom_field_id = custom_fields.id")
      .where("#{restrictions}.restriction = custom_fields.project_specific_value_restriction")
      .select(1)
  end

  def project = context.project
end
