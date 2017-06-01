#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See doc/COPYRIGHT.rdoc for more details.
#++

class Journal < ActiveRecord::Base
  self.table_name = 'journals'

  include JournalChanges
  include JournalFormatter
  include FormatHooks

  register_journal_formatter :diff, OpenProject::JournalFormatter::Diff
  register_journal_formatter :attachment, OpenProject::JournalFormatter::Attachment
  register_journal_formatter :custom_field, OpenProject::JournalFormatter::CustomField

  # Make sure each journaled model instance only has unique version ids
  validates_uniqueness_of :version, scope: [:journable_id, :journable_type]

  belongs_to :user
  belongs_to :journable, polymorphic: true

  has_many :attachable_journals, class_name: Journal::AttachableJournal, dependent: :destroy
  has_many :customizable_journals, class_name: Journal::CustomizableJournal, dependent: :destroy

  after_create :save_data, if: :data
  after_save :save_data, :touch_journable

  # Scopes to all journals excluding the initial journal - useful for change
  # logs like the history on issue#show
  scope :changing, -> { where(['version > 1']) }

  # Ensure that no INSERT/UPDATE/DELETE statements as well as other code inside :with_write_lock
  # is run concurrently to the code inside this block, by using database locking.
  # Note for PostgreSQL: If this is called from inside a transaction, the lock will last until the
  #   end of that transaction.
  # Note for MySQL: THis method does not currently change anything (no locking at all)
  def self.with_write_lock
    if OpenProject::Database.mysql?
      Journal.transaction do
        # MySQL is very weak when combining transactions and locks. Using an emulation layer to
        # automatically release an advisory lock at the end of the transaction
        TransactionalLock::AdvisoryLock.new('journals.write_lock').acquire
        yield
      end
    else
      Journal.transaction do
        ActiveRecord::Base.connection.execute("LOCK TABLE #{table_name} IN SHARE ROW EXCLUSIVE MODE")
        yield
      end
    end
  end

  def changed_data=(changed_attributes)
    attributes = changed_attributes

    if attributes.is_a? Hash and attributes.values.first.is_a? Array
      attributes.each { |k, v| attributes[k] = v[1] }
    end
    data.update_attributes attributes
  end

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
    (journable.journal_editable_by?(user) && self.user == user) || user.admin?
  end

  def details
    get_changes
  end

  # TODO Evaluate whether this can be removed without disturbing any migrations
  alias_method :changed_data, :details

  def new_value_for(prop)
    details[prop].last if details.keys.include? prop
  end

  def old_value_for(prop)
    details[prop].first if details.keys.include? prop
  end

  def data
    @data ||= "Journal::#{journable_type}Journal".constantize.find_by(journal_id: id)
  end

  def data=(data)
    @data = data
  end

  def previous
    predecessor
  end

  private

  def save_data
    data.journal_id = id if data.new_record?
    data.save!
  end

  def touch_journable
    if journable && !journable.changed?
      # Not using touch here on purpose,
      # as to avoid changing lock versions on the journables for this change
      time = journable.send(:current_time_from_proper_timezone)
      attributes = journable.send(:timestamp_attributes_for_update_in_model)

      timestamps = Hash[attributes.map { |column| [column, time] }]
      journable.update_columns(timestamps) if timestamps.any?
    end
  end

  def predecessor
    @predecessor ||= self.class
                     .where(journable_type: journable_type, journable_id: journable_id)
                     .where("#{self.class.table_name}.version < ?", version)
                     .order("#{self.class.table_name}.version DESC")
                     .first
  end

  def journalized_object_type
    "#{journaled_type.gsub('Journal', '')}".constantize
  end
end
