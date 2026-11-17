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

class Queries::TypeVariants::Filters::CustomFieldFilter < Queries::TypeVariants::Filters::TypeVariantFilter
  def self.key
    :custom_field_id
  end

  def type
    :list
  end

  def type_strategy
    @type_strategy ||= ::Queries::Filters::Strategies::IntegerList.new(self)
  end

  def human_name
    WorkPackageCustomField.model_name.human
  end

  def where
    ["type_variants.id IN (?)", variants_showing_custom_field.select(:id)]
  end

  private

  def variants_showing_custom_field
    memberships = FormConfigurationAttribute
    not_excluded = TypeVariant.excluded_custom_field_condition("#{memberships.table_name}.custom_field_id",
                                                               "type_variants.form_configuration_excluded_elements")

    TypeVariant
      .joins(form_configuration: :form_attributes)
      .merge(memberships.active)
      .where(form_configuration_attributes: { custom_field_id: values.first })
      .where(Arel.sql(not_excluded))
      .where("type_variants.project_id IS NULL OR type_variants.project_id IN (?)", Project.active.select(:id))
  end
end
