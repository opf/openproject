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

module Admin
  module SettingsSearch
    class TreeComponent < ApplicationComponent
      def initialize(tree:)
        super()
        @tree = tree
      end

      private

      def add_node(parent, node)
        if node.children.any?
          parent.with_sub_tree(label: node.label, href: node.href, select_variant: :none, data: node_data(node)) do |sub_tree|
            node.children.each { add_node(sub_tree, it) }
          end
        else
          parent.with_leaf(label: leaf_label(node), href: node.href, select_variant: :none, data: node_data(node))
        end
      end

      def leaf_label(node)
        return node.label if node.description.blank?

        safe_join([node.label, tag.span(node.description, class: "sr-only")])
      end

      def node_data(node)
        { node_id: node.key, test_selector: "op-admin-settings-search--node" }
      end
    end
  end
end
