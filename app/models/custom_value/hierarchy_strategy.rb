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

class CustomValue::HierarchyStrategy < CustomValue::ARObjectStrategy
  def formatted_value
    item = cached_ar_object

    return item.to_s if item
    return "" if value.blank?

    "#{value} #{I18n.t(:label_not_found)}"
  end

  def validate_type_of_value
    item = ar_object(value)
    return :invalid unless item

    parent = custom_field.hierarchy_root

    if persistence_service.descendant_of?(item:, parent:).failure?
      :inclusion
    end
  end

  private

  def ar_class
    CustomField::Hierarchy::Item
  end

  def persistence_service
    @persistence_service ||= CustomFields::Hierarchy::HierarchicalItemService.new
  end
end
