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

class Journal < ApplicationRecord
  self.table_name = "journals"
  self.ignored_columns += ["activity_type"]

  include ::JournalChanges
  include ::JournalFormatter
  include ::Acts::Journalized::FormatHooks
  include Journal::Timestamps

  register_journal_formatter OpenProject::JournalFormatter::ActiveStatus
  register_journal_formatter OpenProject::JournalFormatter::AgendaItemDiff
  register_journal_formatter OpenProject::JournalFormatter::AgendaItemDuration
  register_journal_formatter OpenProject::JournalFormatter::AgendaItemPosition
  register_journal_formatter OpenProject::JournalFormatter::AgendaItemTitle
  register_journal_formatter OpenProject::JournalFormatter::Attachment
  register_journal_formatter OpenProject::JournalFormatter::Cause
  register_journal_formatter OpenProject::JournalFormatter::CustomField
  register_journal_formatter OpenProject::JournalFormatter::Diff
  register_journal_formatter OpenProject::JournalFormatter::FileLink
  register_journal_formatter OpenProject::JournalFormatter::IgnoreNonWorkingDays
  register_journal_formatter OpenProject::JournalFormatter::MeetingStartTime
  register_journal_formatter OpenProject::JournalFormatter::MeetingState
  register_journal_formatter OpenProject::JournalFormatter::MeetingWorkPackageId
  register_journal_formatter OpenProject::JournalFormatter::ProjectStatusCode
  register_journal_formatter OpenProject::JournalFormatter::ScheduleManually
  register_journal_formatter OpenProject::JournalFormatter::SubprojectNamedAssociation
  register_journal_formatter OpenProject::JournalFormatter::Template
  register_journal_formatter OpenProject::JournalFormatter::TimeEntryHours
  register_journal_formatter OpenProject::JournalFormatter::TimeEntryNamedAssociation
  register_journal_formatter OpenProject::JournalFormatter::Visibility
  register_journal_formatter OpenProject::JournalFormatter::WikiDiff

  # Attributes related to the cause are stored in a JSONB column so we can easily add new relations and related
  # attributes without a heavy database migration. Fields will be prefixed with `cause_` but are stored in the JSONB
  # hash without that prefix
  store_accessor :cause,
                 %i[
                   type
                   feature
                   work_package_id
                   changed_days
                   status_name
                   status_id
                   status_changes
                 ],
                 prefix: true
  VALID_CAUSE_TYPES = %w[
    default_attribute_written
    progress_mode_changed_to_status_based
    status_changed
    system_update
    work_package_children_changed_times
    work_package_parent_changed_times
    work_package_predecessor_changed_times
    work_package_related_changed_times
    working_days_changed
  ].freeze

  # Make sure each journaled model instance only has unique version ids
  validates :version, uniqueness: { scope: %i[journable_id journable_type] }
  validates :cause_type, inclusion: { in: VALID_CAUSE_TYPES, allow_blank: true }

  belongs_to :user
  belongs_to :journable, polymorphic: true
  belongs_to :data, polymorphic: true, dependent: :destroy

  has_many :attachable_journals, class_name: "Journal::AttachableJournal", dependent: :delete_all
  has_many :customizable_journals, class_name: "Journal::CustomizableJournal", dependent: :delete_all
  has_many :storable_journals, class_name: "Journal::StorableJournal", dependent: :delete_all
  has_many :agenda_item_journals, class_name: "Journal::MeetingAgendaItemJournal", dependent: :delete_all

  has_many :notifications, dependent: :destroy

  # Scopes to all journals excluding the initial journal - useful for change
  # logs like the history on issue#show
  scope :changing, -> { where(["version > 1"]) }

  scope :for_wiki_page, -> { where(journable_type: "WikiPage") }
  scope :for_work_package, -> { where(journable_type: "WorkPackage") }
  scope :for_meeting, -> { where(journable_type: "Meeting") }

  # In conjunction with the included Comparable module, allows comparison of journal records
  # based on their corresponding version numbers, creation timestamps and IDs.
  def <=>(other)
    [version, created_at, id].map(&:to_i) <=> [other.version, other.created_at, other.id].map(&:to_i)
  end

  # Returns whether the version has a version number of 1. Useful when deciding whether to ignore
  # the version during reversion, as initial versions have no serialized changes attached. Helps
  # maintain backwards compatibility.
  def initial?
    version < 2
  end

  # The anchor number for html output
  def anchor
    version - 1
  end

  # Possible shortcut to the associated project
  def project
    if journable.respond_to?(:project)
      journable.project
    elsif journable.is_a? Project
      journable
    end
  end

  def editable_by?(user)
    journable.journal_editable_by?(self, user)
  end

  def details
    get_changes
  end

  def new_value_for(prop)
    details[prop].last if details.key? prop
  end

  def old_value_for(prop)
    details[prop].first if details.key? prop
  end

  def previous
    predecessor
  end

  def successor
    @successor ||= self.class
                       .where(journable_type:, journable_id:)
                       .where("#{self.class.table_name}.version > ?", version)
                       .order(version: :asc)
                       .first
  end

  def noop?
    (!notes || notes&.empty?) && get_changes.empty?
  end

  def has_cause?
    cause_type.present?
  end

  private

  def has_file_links?
    journable.respond_to?(:file_links)
  end

  def predecessor
    @predecessor ||= if initial?
                       nil
                     else
                       self.class
                         .where(journable_type:, journable_id:)
                         .where("#{self.class.table_name}.version < ?", version)
                         .order(version: :desc)
                         .first
                     end
  end
end
