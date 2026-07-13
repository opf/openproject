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
  class BaseContract < ::ModelContract
    include EditableItem

    def self.model
      MeetingAgendaItem
    end

    validate :presenter_can_participate
    validate :validate_work_package_visible

    attribute :meeting
    attribute :work_package
    attribute :meeting_section

    attribute :position
    attribute :title
    attribute :duration_in_minutes
    attribute :notes
    attribute :presenter

    private

    def presenter_can_participate
      return if model.meeting.nil?
      return if model.presenter.nil?
      return if model.presenter.allowed_in_project?(:view_meetings, model.meeting.project)

      errors.add(:presenter, :user_invalid)
    end

    def validate_work_package_visible
      return if model.work_package_id.blank?
      return unless model.new_record? || model.work_package_id_changed?

      unless WorkPackage.visible(user).exists?(id: model.work_package_id)
        errors.add :work_package, :error_not_found
      end
    end
  end
end
