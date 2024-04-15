#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

# In the context of the baseline-comparison feature, this module adds convenience methods
# to the `Journable` class in order to easy access to historic queries.
#
# Usage:
#
#     # Retrieve historic state of single work package
#     work_package = WorkPackage.find(1)
#     historic_work_package = work_package.at_timestamp(1.year.ago)
#     historic_work_package.id         # => 1  (same as work_package.id)
#     historic_work_package.historic?  # => true
#     historic_work_package.save       # raises `ActiveRecord::ReadOnlyRecord`#
#
#     # Filter on historic data
#     WorkPackage.at_timestamp(1.year.ago).where(assigned_to_id: 1)
#
# See also:
#
# - https://github.com/opf/openproject/pull/11243
# - https://community.openproject.org/projects/openproject/work_packages/26448
#
module Journable::Timestamps
  extend ActiveSupport::Concern

  class_methods do
    # Allows to query historic data of journables.
    #
    # For example, to check which work packages were assigned to a
    # specific user one year ago, run:
    #
    #     WorkPackage.where(assigned_to_id: 123).at_timestamp(1.year.ago)
    #
    def at_timestamp(timestamp)
      Journable::HistoricActiveRecordRelation.new(all, timestamp:)
    end

    # There may be database column for the journable class that are not
    # present in the journal-data table, e.g. the 'lock_version' column
    # of the work_packages table.
    #
    def column_names_missing_in_journal
      column_names - journal_class.column_names - ["created_at", "updated_at"]
    end
  end

  prepended do
    if ActiveRecord::Base.connected? and not ActiveRecord::Base.connection.migration_context.needs_migration?
      column_names_missing_in_journal.each do |missing_column_name|
        define_method missing_column_name do
          if historic?
            Rails.logger.warn "Accessing missing column '#{missing_column_name}' on historic data. " \
                              "The column is not present in the '#{self.class.journal_class.table_name}' table."
          end
          super()
        end
      end
    end
  end

  # Instantiates a journable with historic data from the given timestamp.
  #
  #     WorkPackage.find(1).at_timestamp(1.year.ago)
  #
  def at_timestamp(timestamp)
    return unless journal = journals.at_timestamp(timestamp).first

    attributes = journal.data.attributes.merge(
      {
        "id" => id,
        "created_at" => created_at,
        "updated_at" => journal.updated_at,
        "timestamp" => timestamp,
        "journal_id" => journal.id
      }
    )
    self.class.column_names_missing_in_journal.each do |missing_column_name|
      attributes[missing_column_name] = nil
    end
    journable = self.class.instantiate(attributes)
    ::Journable::WithHistoricAttributes.load_custom_values(journable)
    journable.readonly!
    journable
  end

  def historic?
    attributes["timestamp"].present?
  end

  def historical?
    historic?
  end

  # Rollback a journable record to a historic state of that record.
  #
  #     WorkPackage.find(2).at_timestamp(1.year.ago).rollback!
  #
  def rollback!
    raise ActiveRecord::RecordNotSaved, "This is no historic data. You can only revert to historic data." unless historic?

    self.class.find(id).update! attributes.except("id", "timestamp", "journal_id", "created_at", "updated_at")
  end
end
