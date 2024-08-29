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

module Queries::WorkPackages::Filter
  class BudgetFilter < ::Queries::WorkPackages::Filter::WorkPackageFilter
    def allowed_values
      budgets
        .pluck(:subject, :id)
    end

    def available?
      project&.module_enabled?(:budgets)
    end

    def self.key
      :budget_id
    end

    def type
      :list_optional
    end

    def dependency_class
      "::API::V3::Queries::Schemas::BudgetFilterDependencyRepresenter"
    end

    def ar_object_filter?
      true
    end

    def value_objects
      available_budgets = budgets.index_by(&:id)

      values
        .filter_map { |budget_id| available_budgets[budget_id.to_i] }
    end

    def human_name
      WorkPackage.human_attribute_name(:budget)
    end

    private

    def budgets
      Budget
        .where(project_id: project)
        .order(Arel.sql("subject ASC"))
    end
  end
end
