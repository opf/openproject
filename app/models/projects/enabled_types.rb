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

module Projects::EnabledTypes
  extend ActiveSupport::Concern

  included do
    # The type whose configuration applies in this project for the given type's family: the
    # variant this project resolves to, or the family's root when it resolves to none.
    #
    # Every configuration read for a work package has to go through here. Reading an aspect
    # off the type a work package stores answers with the root's configuration and silently
    # ignores the variant.
    def effective_type(type)
      return if type.nil?

      project_types.detect { |project_type| project_type.type_id == type.root_id }&.variant || type.root
    end

    def types_used_by_work_packages
      ::Type.where(id: WorkPackage.where(project_id: project.id)
                                  .select(:type_id)
                                  .distinct)
    end

    # Returns a scope of the types used by the project and its active sub projects
    def rolled_up_types
      ::Type
        .joins(:projects)
        .select("DISTINCT #{::Type.table_name}.*")
        .where(projects: { id: self_and_descendants.select(:id) })
        .merge(Project.active)
        .order("#{::Type.table_name}.position")
    end
  end
end
