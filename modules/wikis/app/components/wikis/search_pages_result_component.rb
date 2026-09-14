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

module Wikis
  class SearchPagesResultComponent < ApplicationComponent
    include ApplicationHelper
    include OpPrimer::ComponentHelpers
    include Components::TreeNodeHelper

    alias_method :tree_nodes, :model

    attr_reader :builder, :form_name, :wikis_selectable

    def initialize(model = [], builder:, form_name:, wikis_selectable:, **)
      @builder = builder
      @form_name = form_name
      @wikis_selectable = wikis_selectable
      super(model, **)
    end

    def build_tree(tree)
      add_sub_tree(tree, tree_nodes)
    end

    private

    def add_sub_tree(parent, nodes)
      nodes.each do |node|
        if node.children.any?
          parent.with_sub_tree(**node_options(node, wikis_selectable:, expanded: true)) do |item|
            item.with_leading_visual_icon(icon: node_icon(node))
            add_sub_tree(item, node.children)
          end
        else
          parent.with_leaf(**node_options(node, wikis_selectable:, expanded: true)) do |item|
            item.with_leading_visual_icon(icon: node_icon(node))
          end
        end
      end
    end
  end
end
