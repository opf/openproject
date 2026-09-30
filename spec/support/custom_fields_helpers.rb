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

module CustomFieldsHelpers
  def factory_bot_custom_field_traits_for(class_name)
    OpenProject::CustomFieldFormat
      .available_for_class_name(class_name)
      .flat_map do |format|
        trait_name = trait_name(format.name)
        [
          trait_name,
          format.multi_value_possible? ? "multi_#{trait_name}" : nil
        ].compact
      end
  end

  def trait_name(custom_field_format_name)
    case custom_field_format_name
    when "int" then "integer"
    when "bool" then "boolean"
    else custom_field_format_name
    end
  end
end
