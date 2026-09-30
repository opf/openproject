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

module MeetingOutcomes
  class CreateWithWorkPackageService
    attr_reader :user, :project

    def initialize(user:, project:)
      @user = user
      @project = project
    end

    def build_work_package(params = {}) # rubocop:disable Metrics/AbcSize
      work_package = WorkPackage.new(project:)
      contract = WorkPackages::CreateContract.new(work_package, user)
      defaults = { type: contract.assignable_types.first }

      call = WorkPackages::SetAttributesService
        .new(model: work_package, user:, contract_class: WorkPackages::CreateContract)
        .call(defaults.merge(params))

      # We ignore errors here, as we only want to build the work package
      call.result.tap do |wp|
        wp.errors.clear
        wp.custom_values.each { |cv| cv.errors.clear }
      end
    end

    def call(meeting_agenda_item:, work_package_params:)
      wp_call = WorkPackages::CreateService.new(user:).call(work_package_params.merge(project:))
      return wp_call unless wp_call.success?

      outcome_call = MeetingOutcomes::CreateService.new(user:).call(
        meeting_agenda_item:,
        work_package_id: wp_call.result.id,
        kind: :work_package
      )

      outcome_call.success? ? outcome_call : ServiceResult.failure(result: wp_call.result, errors: outcome_call.errors)
    end
  end
end
