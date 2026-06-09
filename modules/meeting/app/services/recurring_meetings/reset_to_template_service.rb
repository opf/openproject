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

module RecurringMeetings
  ##
  # Resets a meeting occurrence to the series template's current state.
  # Clears any existing content (sections, agenda items, participants) and
  # replaces it with a fresh copy from the template.
  #
  # Optional +params+ are merged into the final update, e.g.
  #   ResetToTemplateService.new(user:, meeting:, params: { state: :open })
  class ResetToTemplateService < ::BaseServices::BaseCallable
    include ::Shared::ServiceContext

    attr_reader :user, :meeting, :extra_params

    def initialize(user:, meeting:, params: {})
      super()
      @user = user
      @meeting = meeting
      @extra_params = params
    end

    protected

    def perform
      in_context(meeting, send_notifications: false) do
        ServiceResult.new(success: reset_to_template!, result: meeting)
      rescue ActiveRecord::RecordInvalid => e
        ServiceResult.failure(message: e.message)
      end
    end

    private

    def template
      meeting.recurring_meeting.template
    end

    def reset_to_template! # rubocop:disable Naming/PredicateMethod
      meeting.transaction do
        clear_existing_content
        copy_agenda_from_template
        copy_participants_from_template
        meeting.update!(
          { title: template.title, location: template.location, duration: template.duration }
            .merge(extra_params)
        )
      end

      true
    end

    def clear_existing_content
      # Destroy all sections (cascades to agenda items via dependent: :destroy)
      meeting.sections.destroy_all
      meeting.participants.destroy_all
    end

    def copy_agenda_from_template # rubocop:disable Metrics/AbcSize
      template.sections.includes(:agenda_items).find_each do |section|
        new_section = meeting.sections.create!(
          section.attributes.except("id", "meeting_id", "created_at", "updated_at")
        )
        section.agenda_items.each do |item|
          new_item = item.dup
          new_item.meeting_section = new_section

          # A work_package agenda item whose WP was deleted has work_package_id nullified but
          # item_type still set. Skip validations for this state
          skip_validation = new_item.work_package? && new_item.work_package_id.nil?
          new_item.save!(validate: !skip_validation)
        end
      end
    end

    def copy_participants_from_template
      participant_attrs =
        if template.allowed_participants.present?
          template.allowed_participants.collect(&:copy_attributes)
        elsif !user.builtin?
          [{ "user_id" => user.id, "invited" => true }]
        else
          []
        end

      participant_attrs.each do |attrs|
        meeting.participants.create!(attrs)
      end
    end
  end
end
