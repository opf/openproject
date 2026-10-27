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

module WorkPackageTypes
  # Runs a per-project type service over many projects and aggregates the outcome:
  # one dependent result per project, so a refusal names its project without aborting the rest.
  class ProjectAssignments
    def initialize(user:, variant:)
      @user = user
      @variant = variant
    end

    def apply(projects)
      aggregate(projects) do |project|
        source = applied_variant_of(project)

        if source.nil?
          ::Projects::Types::AddService.new(user:, model: project).call(variant:)
        else
          switch_one(project, source:, target: variant)
        end
      end
    end

    def remove(projects)
      aggregate(projects) do |project|
        ::Projects::Types::RemoveService.new(user:, model: project).call(variant:)
      end
    end

    def switch(projects, target:)
      aggregate(projects) do |project|
        switch_one(project, source: applied_variant_of(project), target:)
      end
    end

    private

    attr_reader :user, :variant

    def switch_one(project, source:, target:)
      return ServiceResult.success(result: project) if source == target

      ::Projects::Types::SwitchVariantService.new(user:, model: project).call(source:, target:)
    end

    def applied_variant_of(project) = project.project_types.find_by(type_id: variant.type_id)&.variant

    def aggregate(projects)
      ServiceResult.success(result: variant).tap do |aggregated|
        projects.find_each { |project| aggregated.add_dependent!(yield(project)) }
      end
    end
  end
end
