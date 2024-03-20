#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

module Versions::Scopes
  module SharedWith
    extend ActiveSupport::Concern

    class_methods do
      # Returns a scope of the Versions available
      # in the project either because the project defined it itself
      # or because it was shared with it
      def shared_with(project)
        if project.persisted?
          shared_versions_on_persisted(project)
        else
          shared_versions_by_system
        end
      end

      protected

      def shared_versions_on_persisted(project)
        includes(:project)
          .where(projects: { id: project.id })
          .or(shared_versions_by_system)
          .or(shared_versions_by_tree(project))
          .or(shared_versions_by_hierarchy_or_descendants(project))
          .or(shared_versions_by_hierarchy(project))
      end

      def shared_versions_by_tree(project)
        root = project.root? ? project : project.root

        includes(:project)
          .merge(Project.active)
          .where(projects: { id: root.self_and_descendants.select(:id) })
          .where(sharing: 'tree')
      end

      def shared_versions_by_hierarchy_or_descendants(project)
        includes(:project)
          .merge(Project.active)
          .where(projects: { id: project.ancestors.select(:id) })
          .where(sharing: %w(hierarchy descendants))
      end

      def shared_versions_by_hierarchy(project)
        rolled_up(project)
          .where(sharing: 'hierarchy')
      end

      def shared_versions_by_system
        includes(:project)
          .merge(Project.active)
          .where(sharing: 'system')
      end
    end
  end
end
