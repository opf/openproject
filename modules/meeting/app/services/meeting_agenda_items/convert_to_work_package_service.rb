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

module MeetingAgendaItems
  class ConvertToWorkPackageService
    attr_reader :user, :project

    def initialize(user:, project:)
      @user = user
      @project = project
    end

    # Builds an unsaved WorkPackage with attributes derived from the agenda item,
    # optionally overridden by params (used when the user edits the dialog fields).
    def build_work_package(meeting_agenda_item:, params: {}) # rubocop:disable Metrics/AbcSize
      work_package = WorkPackage.new(project:)
      contract = WorkPackages::CreateContract.new(work_package, user)

      defaults = {
        type: contract.assignable_types.first,
        subject: meeting_agenda_item.title,
        description: build_description(meeting_agenda_item)
      }

      call = WorkPackages::SetAttributesService
        .new(model: work_package, user:, contract_class: WorkPackages::CreateContract)
        .call(defaults.merge(params))

      call.result.tap do |wp|
        wp.errors.clear
        wp.custom_values.each { |cv| cv.errors.clear }
      end
    end

    def call(meeting_agenda_item:, work_package_params:)
      result = nil
      ApplicationRecord.transaction do
        wp_call = WorkPackages::CreateService.new(user:).call(work_package_params.merge(project:))
        unless wp_call.success?
          result = wp_call
          raise ActiveRecord::Rollback
        end

        work_package = wp_call.result
        unless convert_agenda_item(meeting_agenda_item, work_package)
          result = ServiceResult.failure(result: work_package, errors: meeting_agenda_item.errors)
          raise ActiveRecord::Rollback
        end

        result = ServiceResult.success(result: work_package)
      end

      result
    end

    private

    def build_description(meeting_agenda_item)
      meeting_agenda_item.notes.to_s.strip.presence
    end

    def convert_agenda_item(meeting_agenda_item, work_package)
      meeting_agenda_item.item_type = :work_package
      meeting_agenda_item.work_package = work_package
      meeting_agenda_item.title = nil
      meeting_agenda_item.notes = "workPackageValue:#{work_package.id}:description"
      meeting_agenda_item.save # rubocop:disable Rails/SaveBang -- caller inspects the boolean
    end
  end
end
