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

module CustomFields
  class DeleteService < ::BaseServices::Delete
    protected

    def persist(service_result)
      project_ids = project_ids_with_values

      super.tap { |result| journalize_projects(project_ids) if result.success? }
    end

    private

    def project_ids_with_values
      return [] unless model.is_a?(ProjectCustomField)

      model.custom_values.where(customized_type: Project.name).distinct.pluck(:customized_id)
    end

    def journalize_projects(project_ids)
      Project.where(id: project_ids).find_each do |project|
        Journals::CreateService.new(project, user).call
      end
    end
  end
end
