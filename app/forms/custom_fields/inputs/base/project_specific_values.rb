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

module CustomFields::Inputs::Base::ProjectSpecificValues
  private

  def usable_value?(value)
    return true if @custom_field.project_specific_value_restriction.nil?

    @object.project.present? && @custom_field.usable_value_id?(@object.project, value.id)
  end

  # Stored values that are no longer usable stay selected, so that saving the form keeps them.
  def unavailable_list_items(custom_values)
    custom_values.reject(&:available_in_project?).map do |custom_value|
      { label: I18n.t(:label_custom_value_no_longer_available), value: custom_value.value.to_i, selected: true }
    end
  end
end
