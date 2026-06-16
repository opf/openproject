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

module Header
  module Projects
    class NodeComponent < ApplicationComponent
      def initialize(component:, node:, current_project_id:, favorited_ids:, jump:)
        super()
        @component = component
        @node = node
        @current_project_id = current_project_id
        @favorited_ids = favorited_ids
        @jump = jump
      end

      private

      def project = @node[:project]
      def children = @node[:children]
      def current? = project.id == @current_project_id
      def favorited? = @favorited_ids.include?(project.id)
      def expanded? = @node[:expanded]
      def matches_query? = @node[:matches_query]

      def href
        @jump.present? ? helpers.project_path(project.identifier, jump: @jump) : helpers.project_path(project.identifier)
      end

      def label
        helpers.project_node_label(project, favorited: favorited?)
      end
    end
  end
end
