#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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
  self.table_name = 'journals'
  self.ignored_columns += ['activity_type']

  include ::JournalChanges
  include ::JournalFormatter
  include ::Acts::Journalized::FormatHooks

  register_journal_formatter :diff, OpenProject::JournalFormatter::Diff
  register_journal_formatter :attachment, OpenProject::JournalFormatter::Attachment
  register_journal_formatter :custom_field, OpenProject::JournalFormatter::CustomField
  register_journal_formatter :schedule_manually, OpenProject::JournalFormatter::ScheduleManually
  register_journal_formatter :ignore_non_working_days, OpenProject::JournalFormatter::IgnoreNonWorkingDays
  register_journal_formatter :active_status, OpenProject::JournalFormatter::ActiveStatus

  # Make sure each journaled model instance only has unique version ids
  validates :version, uniqueness: { scope: %i[journable_id journable_type] }

  belongs_to :user
  belongs_to :journable, polymorphic: true
  belongs_to :data, polymorphic: true, dependent: :destroy

  has_many :attachable_journals, class_name: 'Journal::AttachableJournal', dependent: :delete_all
  has_many :customizable_journals, class_name: 'Journal::CustomizableJournal', dependent: :delete_all

  has_many :notifications, dependent: :destroy

  # Scopes to all journals excluding the initial journal - useful for change
  # logs like the history on issue#show
  scope :changing, -> { where(['version > 1']) }

  scope :for_wiki_content, -> { where(journable_type: "WikiContent") }
  scope :for_work_package, -> { where(journable_type: "WorkPackage") }

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

  private

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
