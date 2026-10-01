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
  class BrowsePagesComponent < ApplicationComponent
    include Components::TreeNodeHelper

    attr_reader :builder, :form_name, :provider_id, :wikis_selectable

    alias_method :nodes, :model
    def initialize(model, builder, form_name, provider_id, wikis_selectable:)
      super(model)
      @builder = builder
      @form_name = form_name
      @provider_id = provider_id
      @wikis_selectable = wikis_selectable
    end

    def build_tree(tree_view)
      add_node(tree_view, nodes)
    end

    private

    def add_node(parent, nodes)
      nodes.each do |node|
        if node.children.none?
          add_lazy_loaded_subtree(parent, node)
        else
          parent.with_sub_tree(**node_options(node, wikis_selectable:, expanded: true)) do |item|
            item.with_leading_visual_icon(icon: node_icon(node))
            add_node(item, node.children)
          end
        end
      end
    end

    def add_lazy_loaded_subtree(parent, node)
      parent.with_sub_tree(**node_options(node, wikis_selectable:)) do |item|
        item.with_leading_visual_icon(icon: node_icon(node))
        item.with_loading_spinner(src: browse_wiki_pages_path(parent: node.identifier, provider_id:))
      end
    end
  end
end
