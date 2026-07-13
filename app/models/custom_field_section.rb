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

class CustomFieldSection < ApplicationRecord
  OVERVIEW__SIDEBAR_KEY = "sidebar"
  OVERVIEW__MAIN_AREA_KEY = "main_area"
  DEFAULT_OVERVIEW_KEY = OVERVIEW__SIDEBAR_KEY

  acts_as_list scope: [:type]

  validates :name, presence: true

  default_scope { order(:position) }

  store_attribute :display_representation, :overview, :string, default: DEFAULT_OVERVIEW_KEY

  def shown_in_overview_sidebar?
    overview == OVERVIEW__SIDEBAR_KEY
  end

  def shown_in_overview_main_area?
    overview == OVERVIEW__MAIN_AREA_KEY
  end

  # Append key to the end of the ordered list (or at a specific 1-indexed position).
  # Idempotent: removes any existing occurrence first.
  def add_to_order(key, position: nil)
    keys = attribute_order.reject { |k| k == key }
    if position && position > 0
      keys.insert(position - 1, key)
    else
      keys << key
    end
    update_column(:attribute_order, keys)
  end

  def remove_from_order(key)
    update_column(:attribute_order, attribute_order.reject { |k| k == key })
  end

  def custom_fields_by_key
    custom_fields.index_by(&:column_name)
  end

  def custom_fields_in_order
    cf_by_key = custom_fields_by_key
    attribute_order.filter_map { |key| cf_by_key[key] }
  end

  # move_to: :highest | :higher | :lower | :lowest
  def move_in_order(key, move_to)
    idx = attribute_order.index(key)
    return unless idx

    keys = attribute_order.dup
    keys.delete_at(idx)
    new_idx = case move_to.to_sym
              when :highest then 0
              when :lowest  then keys.size
              when :higher  then [idx - 1, 0].max
              when :lower   then [idx + 1, keys.size].min
              else return
              end
    keys.insert(new_idx, key)
    update_column(:attribute_order, keys)
  end
end
