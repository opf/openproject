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

module Projects::Exports::PDFExport
  module InfoMap
    def build_flat_meta_infos_map(projects)
      infos_map = projects.map.with_index do |project, index|
        [project.id, { level_path: [index + 1], level: 0, children: [], project: }]
      end.to_h
      [infos_map, projects.to_a]
    end

    def init_meta_infos_map_nodes(projects)
      projects.to_h do |project|
        [project.id, { level_path: [], level: 0, children: [], project: }]
      end
    end

    def link_meta_infos_map_nodes(infos_map, projects)
      projects.reject { |wp| wp.parent_id.nil? }.each do |project|
        parent = infos_map[project.parent_id]
        infos_map[project.id][:parent] = parent
        parent[:children].push(infos_map[project.id]) if parent
      end
      infos_map
    end

    def build_meta_infos_map(projects)
      # build a quick access map for the hierarchy tree
      infos_map = init_meta_infos_map_nodes projects
      # connect parent and children (only wp available in the query)
      infos_map = link_meta_infos_map_nodes infos_map, projects
      # recursive travers creating level index path e.g. [1, 2, 1] from root nodes
      root_nodes = infos_map.values.select { |node| node[:parent].nil? }
      flat_list = []
      fill_meta_infos_map_nodes({ children: root_nodes }, [], flat_list)
      [infos_map, flat_list]
    end

    def fill_meta_infos_map_nodes(node, level_path, flat_list)
      node[:level_path] = level_path
      flat_list.push(node[:project]) unless node[:project].nil?
      index = 1
      node[:children].each do |sub|
        fill_meta_infos_map_nodes(sub, level_path + [index], flat_list)
        index += 1
      end
    end
  end
end
