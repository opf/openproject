#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

module OpenProject::Costs
  class WorkPackageFilter < ::Queries::WorkPackages::Filter::WorkPackageFilter
    def allowed_values
      cost_objects
        .pluck(:subject, :id)
    end

    def available?
      project &&
        project.module_enabled?(:costs_module)
    end

    def self.key
      :cost_object_id
    end

    def order
      14
    end

    def type
      :list_optional
    end

    def dependency_class
      '::API::V3::Queries::Schemas::CostObjectFilterDependencyRepresenter'
    end

    def ar_object_filter?
      true
    end

    def value_objects
      available_cost_objects = cost_objects.index_by(&:id)

      values
        .map { |cost_object_id| available_cost_objects[cost_object_id.to_i] }
        .compact
    end

    def human_name
      WorkPackage.human_attribute_name(:cost_object)
    end

    private

    def cost_objects
      CostObject
        .where(project_id: project)
        .order(Arel.sql('subject ASC'))
    end
  end
end
