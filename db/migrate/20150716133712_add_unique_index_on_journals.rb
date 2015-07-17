#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

class AddUniqueIndexOnJournals < ActiveRecord::Migration
  def up
    cleanup_duplicate_journals
    add_index :journals, [:journable_type, :journable_id, :version], unique: true
  end

  def down
    remove_index :journals, [:journable_type, :journable_id, :version]
  end

  private

  def cleanup_duplicate_journals
    duplicate_pairs = find_duplicate_journal_ids

    if duplicate_pairs.any?
      say "Found #{duplicate_pairs.count} journals with at least one duplicate!"
      say_with_time 'Safely removing duplicates...' do
        undeleted_pairs = []
        duplicate_pairs.each do |current_id, duplicate_id|
          say "Comparing journals ##{current_id} & ##{duplicate_id} for equality", subitem: true

          current = MigrationHelperJournal.find(current_id)
          duplicate = MigrationHelperJournal.find(duplicate_id)

          if journals_equivalent?(current, duplicate)
            say "Deleting journal ##{current.id}...", subitem: true
            current.destroy
          else
            undeleted_pairs << [current_id, duplicate_id]
          end
        end

        abort_on_undeleted_pairs undeleted_pairs
      end
    end
  end

  def find_duplicate_journal_ids
    this = MigrationHelperJournal.table_name
    MigrationHelperJournal
      .joins("INNER JOIN #{this} other
      ON #{this}.journable_id = other.journable_id AND
         #{this}.journable_type = other.journable_type AND
         #{this}.version = other.version")
      .where("#{this}.id < other.id")
      .select("#{this}.id id, other.id duplicate_id")
      .uniq_by(&:id)
      .map { |pair| [pair.id, pair.duplicate_id] }
  end

  def journals_equivalent?(a, b)
    unless records_equivalent?(a, b)
      say 'Difference found in table journals', subitem: true
      return false
    end

    unless records_equivalent?(a.data, b.data)
      say 'Difference found in related data table (e.g. work_package_journals)', subitem: true
      return false
    end

    a_attachments = a.attachable_journals.pluck(:attachment_id).sort
    b_attachments = b.attachable_journals.pluck(:attachment_id).sort
    unless a_attachments == b_attachments
      say 'Difference found in attachable_journals', subitem: true
      return false
    end

    a_custom_fields = customizable_journals_to_hash a.customizable_journals
    b_custom_fields = customizable_journals_to_hash b.customizable_journals
    unless a_custom_fields == b_custom_fields
      say 'Difference found in customizable_journals', subitem: true
      return false
    end

    true
  end

  def records_equivalent?(a, b)
    if a.nil? || b.nil?
      return a == b
    end

    ignored = [:id, :journal_id, :created_at, :updated_at]
    a.attributes.symbolize_keys.except(*ignored) == b.attributes.symbolize_keys.except(*ignored)
  end

  def customizable_journals_to_hash(customizable_journals)
    customizable_journals.inject({}) { |hash, custom_journal|
      hash[custom_journal.custom_field_id] = custom_journal.value
      hash
    }
  end

  def abort_on_undeleted_pairs(undeleted_pairs)
    return unless undeleted_pairs.any?

    say '', subitem: true
    say 'There were journals that had a duplicate, but were not deleted.', subitem: true
    say 'You have to manually decide how to proceed with these journals.', subitem: true
    say 'Please compare the corresponding entries in the following tables:', subitem: true
    say ' * journals', subitem: true
    say ' * attachable_journals', subitem: true
    say ' * customizable_journals', subitem: true
    say ' * {type}_journals, with {type} being indicated by the journable_type', subitem: true
    say '', subitem: true
    say 'The following table lists the remaining duplicate pairs,', subitem: true
    say 'note that only one entry per pair is supposed to be deleted:', subitem: true

    column_width = 20
    say '-' * (column_width *  2 + 7), subitem: true
    say "| #{'journal 1'.rjust(column_width)} | #{'journal 2'.rjust(column_width)} |", subitem: true
    say '-' * (column_width *  2 + 7), subitem: true
    undeleted_pairs.each do |undeleted_id, duplicate_id|
      say "| #{undeleted_id.to_s.rjust(column_width)} | #{duplicate_id.to_s.rjust(column_width)} |",
          subitem: true
    end
    say '-' * (column_width *  2 + 7), subitem: true

    raise "Can't continue migration safely because of duplicate journals!"
  end

  # Using a custom (light weight) implementation of Journal here, because we don't know
  # how the original might change in the future. Changes could potentially break our untested
  # migrations. By providing a minimal custom implementation, I hope to reduce that risk.
  class MigrationHelperJournal < ActiveRecord::Base
    self.table_name = 'journals'

    has_many :attachable_journals,
             class_name: Journal::AttachableJournal,
             foreign_key: :journal_id,
             dependent: :destroy
    has_many :customizable_journals,
             class_name: Journal::CustomizableJournal,
             foreign_key: :journal_id,
             dependent: :destroy

    def data
      @data ||= "Journal::#{journable_type}Journal".constantize.where(journal_id: id).first
    end
  end
end
