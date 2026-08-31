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

module CustomFieldHierarchyTreeViewHelper
  def populate_tree_view(tree_view, custom_field, show_root: false, item_options: {})
    hierarchy_hash = custom_field.hierarchy_root.hash_tree

    return if hierarchy_hash.nil?

    if show_root
      hierarchy_hash.keys.first.label = custom_field.name
    else
      hierarchy_hash = hierarchy_hash.first[1]
    end

    add_sub_tree(tree_view, hierarchy_hash, item_options)
  end

  def standard_tree_view_item_formatter
    ::CustomFields::Hierarchy::HierarchicalItemFormatter.new(number_integer_digit_limit: 8,
                                                             number_length_limit: 9,
                                                             number_precision: 4)
  end

  private

  def add_sub_tree(tree, hierarchy_hash, item_options)
    hierarchy_hash.each do |item, child_hash|
      if child_hash.empty?
        tree.with_leaf(**item_attributes(item, item_options))
      else
        tree.with_sub_tree(**item_attributes(item, item_options)) do |sub_tree|
          add_sub_tree(sub_tree, child_hash, item_options)
        end
      end
    end
  end

  def item_attributes(item, options) # rubocop:disable Metrics/PerceivedComplexity,Metrics/AbcSize
    {
      label: options[:label_fn]&.call(item) || item.label,
      value: item.id,
      select_variant: options[:select_variant] || :none,
      checked: options[:checked_fn]&.call(item) || false,
      current: options[:current] == item,
      disabled: options[:disabled]&.include?(item) || false,
      expanded: options[:expanded_fn]&.call(item) || options[:expanded]&.include?(item) || false,
      href: options[:href_fn]&.call(item)
    }
  end
end
