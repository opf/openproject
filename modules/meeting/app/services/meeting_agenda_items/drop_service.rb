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

module MeetingAgendaItems
  class DropService < ::BaseServices::BaseCallable
    include JournalizeWorkPackageActivity

    attr_reader :user

    def initialize(user:, meeting_agenda_item:)
      super()
      @user = user
      @meeting_agenda_item = meeting_agenda_item
      @meeting = meeting_agenda_item.meeting
      @old_section = meeting_agenda_item.meeting_section
    end

    def perform
      service_call = validate_permission
      service_call = validate_meeting_existence if service_call.success?
      service_call = validate_meeting_agenda_item_editable if service_call.success?
      service_call = validate_manual_ordering if service_call.success?

      service_call = perform_drop(service_call, params) if service_call.success?

      if service_call.success?
        journalize_move_on_work_package
        journalize_meetings
      end

      # after_perform(service_call) if service_call.success? # TODO properly integrate after_perform_hook

      service_call
    end

    def validate_permission
      if @user.allowed_in_project?(:manage_agendas, @meeting.project)
        ServiceResult.success
      else
        ServiceResult.failure(errors: { base: :error_unauthorized })
      end
    end

    def validate_meeting_existence
      if @meeting.present?
        ServiceResult.success
      else
        ServiceResult.failure(errors: { base: :does_not_exist })
      end
    end

    def validate_meeting_agenda_item_editable
      if @meeting_agenda_item.editable?
        ServiceResult.success
      else
        ServiceResult.failure(errors: { base: :error_unauthorized })
      end
    end

    def perform_drop(service_call, params) # rubocop:disable Metrics/AbcSize
      new_section_id = params[:target_id]&.to_i
      section_changed = @old_section.id != new_section_id

      if section_changed
        move_call = move_to_section(target_section(new_section_id))
        return move_call if move_call.failure?
      end

      update_position(params[:position]&.to_i)

      service_call.result = { section_changed:,
                              current_section: @meeting_agenda_item.meeting_section,
                              old_section: (@old_section if section_changed) }
      service_call
    rescue StandardError => e
      service_call.success = false
      service_call.errors.add(:base, e.message)
      service_call
    end

    private

    def validate_manual_ordering
      if @meeting_agenda_item.vote_based_ordering? && params[:target_id].to_i == @meeting_agenda_item.meeting_section_id
        @meeting_agenda_item.errors.add :base, I18n.t("meeting.agenda_sorting.manual_order_disabled")
        ServiceResult.failure(result: @meeting_agenda_item, errors: @meeting_agenda_item.errors)
      else
        ServiceResult.success
      end
    end

    def journalize_meetings
      [@old_section.meeting, @meeting_agenda_item.meeting].uniq.each(&:save_journals)
    end

    def journalize_move_on_work_package
      return if @old_section.meeting_id == @meeting_agenda_item.meeting_id

      destination = @meeting_agenda_item.meeting
      source_meeting = @old_section.meeting if destination.series_template?

      journalize_agenda_item(@meeting_agenda_item,
                             Journal::CausedByMeetingAgendaItemMoved.new(destination, source_meeting:))
    end

    def move_to_section(new_section)
      @meeting_agenda_item.meeting_section = new_section
      contract = UpdateContract.new(@meeting_agenda_item, user)

      if contract.validate
        @meeting_agenda_item.save!
        ServiceResult.success
      else
        ServiceResult.failure(errors: contract.errors)
      end
    end

    def update_position(new_position)
      return if @meeting_agenda_item.vote_based_ordering?

      @meeting_agenda_item.insert_at(new_position)
    end

    def target_section(new_section_id)
      if @meeting.backlog == @old_section
        # UpdateContract#section_belongs_to_meeting limits backlog items to the meetings of their series
        MeetingSection.joins(:meeting).merge(Meeting.visible(user)).find(new_section_id)
      elsif @meeting.backlog&.id == new_section_id
        @meeting.backlog
      else
        @meeting.sections.find(new_section_id)
      end
    end
  end
end
