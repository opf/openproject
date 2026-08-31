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
#

class MeetingAgendaItem < ApplicationRecord
  ITEM_TYPES = {
    simple: 0,
    work_package: 1
  }.freeze

  enum :item_type, ITEM_TYPES

  belongs_to :meeting
  belongs_to :meeting_section, optional: false
  belongs_to :work_package, class_name: "::WorkPackage"
  has_one :project, through: :meeting
  belongs_to :author, class_name: "User", optional: false
  belongs_to :presenter, class_name: "User", optional: true

  has_many :outcomes,
           -> { order(id: :asc) },
           class_name: "MeetingOutcome",
           dependent: :destroy,
           inverse_of: :meeting_agenda_item

  acts_as_list scope: :meeting_section
  default_scope { order(:position) }

  scope :with_includes_to_render, -> { includes(:author, :meeting) }

  def self.linked_to_work_package(work_package)
    where(<<~SQL.squish, wp_id: work_package.id)
      meeting_agenda_items.work_package_id = :wp_id OR
      meeting_agenda_items.id IN (
        SELECT meeting_agenda_item_id FROM meeting_outcomes WHERE meeting_outcomes.work_package_id = :wp_id
      )
    SQL
  end

  def self.visible_linked_to_work_package(user, work_package)
    linked_to_work_package(work_package)
      .where(meeting_id: Meeting.not_templated.visible(user))
  end

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
  before_save :update_meeting_to_match_section
  after_update :delete_default_section_if_last_item_moved, if: :saved_change_to_meeting_section_id?
  after_destroy :delete_default_section_if_last_item_deleted

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

  def display_title
    if visible_work_package?
      work_package.to_s
    elsif linked_work_package?
      I18n.t(:label_agenda_item_undisclosed_wp, id: work_package_id)
    elsif deleted_work_package?
      I18n.t(:label_agenda_item_deleted_wp)
    else
      title
    end
  end

  def delete_default_section_if_last_item_deleted
    return if meeting_section.nil? || meeting.sections.count > 1 || meeting_section.backlog?

    check_and_destroy(meeting_section)
  end

  def delete_default_section_if_last_item_moved
    old_section_id = saved_change_to_meeting_section_id.first
    old_section = MeetingSection.find_by(id: old_section_id)
    return if old_section.nil? || old_section.backlog?

    check_and_destroy(old_section)
  end

  def check_and_destroy(section)
    # Only destroy the auto created default section, discernible via the blank title
    if section.agenda_items.empty? && section.title.blank?
      section.destroy
    end
  end

  def update_meeting_to_match_section
    # TODO - see #63561
    self.meeting = meeting_section.meeting
  end

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
    !meeting&.closed?
  end

  def copy_attributes
    attributes.except("id", "meeting_id")
  end

  def in_backlog?
    meeting_section.backlog?
  end
end
