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
  belongs_to :project, optional: true
  has_closure_tree order: "sort_order", numeric_order: true, dont_order_roots: true, dependent: :destroy
  counter_culture :parent, column_name: :children_count

  normalizes :short, with: ->(short) { short.presence }

  validates :weight, numericality: true, allow_nil: true

  scope :including_children, -> { includes(children: :children) }
  scope :with_label_ignoring_case, ->(label) { where("LOWER(#{table_name}.label) = LOWER(?)", label) }
  scope :with_short_ignoring_case, ->(short) { where("LOWER(#{table_name}.short) = LOWER(?)", short) }

  def to_s = formatter.format(item: self)

  def descendants_preordered = self_and_descendants_preordered.offset(1)

  def place_under(parent, before: nil)
    siblings = parent.children.where.not(id:)
    anchor = anchor_sibling(siblings, before)
    last_sibling = siblings.last

    if anchor
      anchor.prepend_sibling(self)
    elsif last_sibling
      last_sibling.append_sibling(self)
    else
      parent.add_child(self)
    end
  end

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

  # Project items are always kept after the global items of the same parent.
  def anchor_sibling(siblings, before)
    requested = siblings.find_by(sort_order: [before, 0].max) unless before.nil?
    return requested if requested && requested.project_id.nil? == project_id.nil?

    siblings.where.not(project_id: nil).first if project_id.nil?
  end

  def formatter
    CustomFields::Hierarchy::HierarchicalItemFormatter.default
  end
end
