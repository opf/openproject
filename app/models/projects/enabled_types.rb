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
    def enabled_types
      ::Type.enabled_in(self)
    end

    def enabled_variants
      ::TypeVariant
        .where(id: project_types.select(:variant_id))
        .joins(:type)
        .order(::Type.arel_table[:position].asc)
    end

    def type_variant(type)
      return if type.nil?

      project_type = if association(:project_types).loaded?
                       project_types.find { |candidate| candidate.type_id == type.id }
                     else
                       project_types.find_by(type_id: type.id)
                     end

      project_type&.variant || type.default_variant
    end

    def type_variants(*types)
      type_ids = types.flatten.map { |type| type.respond_to?(:id) ? type.id : type }
      applied = ProjectType.where(project_id: id, type_id: type_ids)

      ::TypeVariant.where(id: applied.select(:variant_id))
                   .or(::TypeVariant.default_variant.where(type_id: type_ids)
                                         .where.not(type_id: applied.select(:type_id)))
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
