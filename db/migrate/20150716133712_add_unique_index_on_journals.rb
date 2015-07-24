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

# Adds a unique index over three columns of the journals table that should form a composite key.
# Because we know that production data will not fit that assumption, we perform an automatic cleanup
# before adding the Index:
#  1. remove perfectly identical duplicates:
#     Those may appear by clicking multiple times on the submit button of a form
#  2. issue new version numbers for duplicates with different content
#     May arise due to quick automated updates (e.g. bots posting comments)
# In general we learned that up until now OpenProject was not very good at handling concurrent
# updates to journables. By adding the index we ensure data consistency, but at the same time
# provoke errors in those update scenarios.
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

      inconsistent_journables = []
      say_with_time 'Safely removing duplicates...' do
        duplicate_pairs.each do |current_id, duplicate_id|
          sub_say "Comparing journals ##{current_id} & ##{duplicate_id} for equality"

          current = MigrationHelperJournal.find(current_id)
          duplicate = MigrationHelperJournal.find(duplicate_id)

          if journals_equivalent?(current, duplicate)
            sub_say "Deleting journal ##{current.id}..."
            current.destroy
          else
            inconsistent_journables << [current.journable_type, current.journable_id]
          end
        end
      end

      reorder_journals_for inconsistent_journables
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

  def reorder_journals_for(journables)
    if journables.any?
      say_with_time 'Reordering journables with duplicate journals...' do
        journables.uniq!
        journables.each do |type, id|
          sub_say "Reordering journals for #{type} ##{id}"
          journals = Journal
                       .where(journable_type: type, journable_id: id)
                       .order('version ASC, created_at ASC')
          journals.each_with_index do |journal, index|
            version = index + 1
            Journal.where(id: journal.id).update_all(version: version)
          end
        end
      end
    end
  end

  def journals_equivalent?(a, b)
    base_journals_equivalent?(a, b) &&
      specific_journals_equivalent?(a, b) &&
      attachable_journals_equivalent?(a, b) &&
      customizable_journals_equivalent?(a, b)
  end

  def base_journals_equivalent?(a, b)
    result = records_equivalent?(a, b)
    sub_say 'Difference found in table journals' unless result
    result
  end

  def specific_journals_equivalent?(a, b)
    result = records_equivalent?(a.data, b.data)
    sub_say 'Difference found in related data table (e.g. work_package_journals)' unless result
    result
  end

  def attachable_journals_equivalent?(a, b)
    a_attachments = a.attachable_journals.pluck(:attachment_id).sort
    b_attachments = b.attachable_journals.pluck(:attachment_id).sort
    result = a_attachments == b_attachments
    sub_say 'Difference found in attachable_journals' unless result
    result
  end

  def customizable_journals_equivalent?(a, b)
    a_custom_fields = customizable_journals_to_hash a.customizable_journals
    b_custom_fields = customizable_journals_to_hash b.customizable_journals
    result = a_custom_fields == b_custom_fields
    sub_say 'Difference found in customizable_journals' unless result
    result
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

  def sub_say(message)
    say message, subitem: true
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
