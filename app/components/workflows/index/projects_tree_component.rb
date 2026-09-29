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

module Workflows
  module Index
    class ProjectsTreeComponent < ApplicationComponent
      include OpPrimer::ComponentHelpers

      def initialize(nodes:, builder:, form_name:, checked_ids: [])
        super()

        @nodes = nodes
        @builder = builder
        @form_name = form_name
        @checked_ids = Array(checked_ids).map(&:to_s)
      end

      def build_tree(tree)
        add_sub_tree(tree, nodes)
      end

      private

      attr_reader :nodes, :builder, :form_name, :checked_ids

      def add_sub_tree(parent, level)
        level.each do |node|
          if node[:children].any?
            parent.with_sub_tree(select_strategy: :self, **item_options(node[:project])) do |sub_tree|
              add_sub_tree(sub_tree, node[:children])
            end
          else
            parent.with_leaf(**item_options(node[:project]))
          end
        end
      end

      def item_options(project)
        {
          label: project.name,
          select_variant: :multiple,
          checked: checked_ids.include?(project.id.to_s),
          expanded: true,
          data: { node_id: project.id }
        }
      end
    end
  end
end
