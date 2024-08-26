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
#

class MeetingAgendaItem < ApplicationRecord
  ITEM_TYPES = {
    simple: 0,
    work_package: 1
  }.freeze

  enum item_type: ITEM_TYPES

  belongs_to :meeting, class_name: "StructuredMeeting"
  belongs_to :meeting_section, optional: false
  belongs_to :work_package, class_name: "::WorkPackage"
  has_one :project, through: :meeting
  belongs_to :author, class_name: "User", optional: false
  belongs_to :presenter, class_name: "User", optional: true

  acts_as_list scope: :meeting_section
  default_scope { order(:position) }

  scope :with_includes_to_render, -> { includes(:author, :meeting) }

  # The primer form depends on meeting_id being validated, even though Rails pattern would suggest
  # to validate only :meeting. When copying meetings however,
  # we build meetings and agenda items together, so meeting_id will stay empty.
  # We can use loaded? to check if the meeting has been provided
  validates :meeting_id, presence: true, unless: Proc.new { |item| item.association(:meeting).loaded? && item.meeting }
  validates :title, presence: true, if: Proc.new { |item| item.simple? }
  validates :work_package_id, presence: true, if: Proc.new { |item| item.work_package? }, on: :create
  validates :work_package_id,
            presence: true,
            if: Proc.new { |item| item.work_package? && item.work_package_id_changed? },
            on: :update
  validates :duration_in_minutes,
            numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 1440 },
            allow_nil: true

  before_validation :add_to_latest_meeting_section

  after_create :trigger_meeting_agenda_item_time_slots_calculation
  after_save :trigger_meeting_agenda_item_time_slots_calculation, if: Proc.new { |item|
    item.duration_in_minutes_previously_changed? || item.position_previously_changed?
  }
  after_destroy :trigger_meeting_agenda_item_time_slots_calculation
  # after_destroy :delete_meeting_section_if_empty

  def add_to_latest_meeting_section
    return if meeting.nil?

    if meeting_section_id.nil?
      meeting_section = meeting.sections.order(position: :asc).last

      if meeting_section.nil?
        meeting_section = meeting.sections.build(title: "")
      end

      self.meeting_section = meeting_section
    end
  end

  def trigger_meeting_agenda_item_time_slots_calculation
    meeting.calculate_agenda_item_time_slots
  end

  # def delete_meeting_section_if_empty
  #   # we need to delete the last existing section if the last meeting agenda item is deleted
  #   # as we don't render the section (including the section menu) if only one section exists
  #   # thus the section would silently exist in the database when the very last agenda item was deleted
  #   # which makes UI rendering inconsistent
  #   meeting_section.destroy if meeting_section.agenda_items.empty? && meeting.sections.count == 1
  # end

  def linked_work_package?
    item_type == "work_package" && work_package.present?
  end

  def visible_work_package?
    linked_work_package? && work_package.visible?(User.current)
  end

  def deleted_work_package?
    persisted? && item_type == "work_package" && work_package_id_was.nil?
  end

  def editable?
    !(meeting&.closed? || deleted_work_package?)
  end

  def modifiable?
    !(meeting&.closed? || (deleted_work_package? && work_package_id.present?))
  end

  def copy_attributes
    attributes.except("id", "meeting_id")
  end
end
