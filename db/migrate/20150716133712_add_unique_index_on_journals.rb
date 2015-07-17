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
        duplicate_pairs.each do |current_id, duplicate_id|
          say "Comparing journals ##{current_id} & ##{duplicate_id} for equality", subitem: true

          current = MigrationHelperJournal.find(current_id)
          duplicate = MigrationHelperJournal.find(duplicate_id)

          if journals_equivalent?(current, duplicate)
            say "Deleting journal ##{current.id}...", subitem: true
            current.destroy
          else
            abort_migration(current, duplicate)
          end
        end
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
    records_equivalent?(a, b) && records_equivalent?(a.data, b.data)
  end

  def records_equivalent?(a, b)
    if a.nil? || b.nil?
      return a == b
    end

    ignored = [:id, :journal_id, :created_at, :updated_at]
    a.attributes.symbolize_keys.except(*ignored) == b.attributes.symbolize_keys.except(*ignored)
  end

  def abort_migration(current, duplicate)
    say "Won't delete ##{current.id}, because its content is different from ##{duplicate.id}",
        subitem: true
    say 'You have to manually decide whether it is safe to delete one of both journals.',
        subitem: true
    say 'Aborting migration...', subitem: true

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
