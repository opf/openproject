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

module Overviews
  class PredefinedFilterListComponent < ApplicationComponent
    def initialize(filter:, query:, project:, current_user:)
      super()
      @filter = filter
      @query = query
      @project = project
      @current_user = current_user
    end

    private

    def groups
      return {} unless @query.valid?

      work_packages = @query.results.work_packages.includes(:status, :type, :project).to_a
      return {} if work_packages.empty?
      return { t(:label_work_package_plural) => work_packages } unless @query.group_by?

      work_packages.group_by { |work_package| group_value(work_package) }
    end

    def group_value(work_package)
      value = @query.group_by_column.value(work_package)
      if @query.group_by == "project_phase"
        value if value&.active?
      elsif value.is_a?(ActiveRecord::Relation)
        value.to_a
      else
        value
      end
    end

    def group_label(group)
      return t(:label_none) if group.blank?

      Array.wrap(group).map { |value| value.respond_to?(:name) ? value.name : value }.join(", ")
    end
  end
end
