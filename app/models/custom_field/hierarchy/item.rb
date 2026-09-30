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

class CustomField::Hierarchy::Item < ApplicationRecord
  self.table_name = "hierarchical_items"

  belongs_to :custom_field
  has_closure_tree order: "sort_order", numeric_order: true, dont_order_roots: true, dependent: :destroy
  counter_culture :parent, column_name: :children_count

  scope :including_children, -> { includes(children: :children) }

  def to_s = formatter.format(item: self)

  # @deprecated Use [CustomFields::Hierarchy::HierarchicalItemFormatter] instead.
  def ancestry_path(include_shorts_and_weights: false)
    path = self_and_ancestors.filter_map(&:label).reverse.join(" / ")

    return path unless include_shorts_and_weights

    suffix.empty? ? path : "#{path} #{suffix}"
  end

  # @deprecated Use [CustomFields::Hierarchy::HierarchicalItemFormatter] instead.
  def suffix
    return "" if short.nil? && weight.nil?

    "(#{short || weight})"
  end

  private

  def formatter
    CustomFields::Hierarchy::HierarchicalItemFormatter.default
  end
end
