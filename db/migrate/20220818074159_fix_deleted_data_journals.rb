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

class FixDeletedDataJournals < ActiveRecord::Migration[7.0]
  def up
    get_missing_journals.each do |journable_type, relation|
      Rails.logger.debug { "Cleaning up journals on #{journable_type}" }

      if unmigratable_journal_classes.key?(journable_type) && relation.count > 0
        raise <<~ERROR
          We have found missing journal entries for the #{journable_type} model.

          Unfortunately, you cannot update directly to OpenProject #{OpenProject::VERSION.to_semver},
          as subsequent migrations are not yet processed for this model.

          To fix this issue, please try one of these options:

          Upgrade first to Openproject 13.0.0, and then to this version.

          ----

          Skip this migration by connecting to the database, and running the following SQL command:

          INSERT INTO schema_migrations (version) VALUES (20220818074159);

          Then, run this migration step again. It will skip this migration.

          Once migrated, remove this migration entry again by running this SQL command:

          DELETE FROM schema_migrations WHERE version='20220818074159';

          Then, run this migration step again. Only this skipped migration will be performed.
        ERROR
      end

      relation.find_each { |journal| fix_journal_data(journal) }

      count = relation.count
      unfixed_journals_found(journable_type, relation, count) if count > 0
    end
  end

  def down
    # nothing to do
  end

  def unfixed_journals_found(journable_type, relation, count)
    unless ENV["SKIP_MISSING_JOURNALS"] == "true"
      warning = <<~WARNING
        There shouldn't be any missing data left for #{journable_type}, but found #{count}.

        You can choose to ignore this error by setting the environment variable `SKIP_MISSING_JOURNALS=true`
        and re-run the migration / configure step.

        This will allow the migration to continue and print the affected journals.
        Please report them to this bug ticket in our community: https://community.openproject.org/wp/43839

        Aborting the migration at this point.
      WARNING

      raise warning
    end

    warning = ["SKIP_MISSING_JOURNALS was set to true."]
    warning << "Please add the following output to the bug ticket in our community: https://community.openproject.org/wp/43839"

    warning << "--- BEGIN ---"
    relation.find_each do |journal|
      warning << "Journal -> #{journal.inspect}"
      warning << "Journable? -> #{journal.journable.inspect}"
      warning << "Predecessor? -> #{journal.previous.inspect}"
      warning << "Successor? -> #{journal.successor.inspect}"
    end

    warning << "--- END ---"
    warn warning.join("\n")
  end

  def fix_journal_data(journal)
    # Best case, no successor
    # restore data from work package itself
    if journal.successor.nil?
      raise "Previous also has data nil" if journal.previous && journal.previous.data.nil?

      insert_journal_data(journal, write_message: false)
    elsif (predecessor = journal.previous)
      # Case 2, we do have a predecessor
      take_over_from_source(journal, predecessor)
    elsif journal.successor
      # Case 3, We are the first, but have a successor
      # Look for data in the successor
      take_over_from_successor(journal)
    else
      raise "This should not happen for #{journal.inspect}"
    end
  end

  def insert_journal_data(journal, write_message: false)
    service = Journals::CreateService.new(journal.journable, User.system)
    insert_sql = service.instance_eval { insert_data_sql("placeholder", nil) }

    result = Journal.connection.uncached do
      ::Journal
        .connection
        .select_one(insert_sql)
    end

    raise "ID is missing #{result.inspect}" unless result["id"]

    if write_message
      update_with_new_data!(journal, result["id"])
    else
      journal.update_column(:data_id, result["id"])
    end
  end

  def get_missing_journals
    Journal
      .pluck("DISTINCT(journable_type)")
      .to_h do |journable_type|
      journal_class, table_name = lookup_journal_class_table(journable_type)
      relation = Journal
        .joins("LEFT OUTER JOIN #{table_name} ON journals.data_type = '#{journal_class}' AND #{table_name}.id = journals.data_id")
        .where("#{table_name}.id IS NULL")
        .where(journable_type:)
        .where.not(data_type: nil) # Ignore special tenants with data_type nil errors
        .order("journals.version ASC")
        .includes(:journable)

      [journable_type, relation]
    end
  end

  # Lookup table for items that were already deleted
  def lookup_journal_class_table(journable_type)
    unmigratable_journal_classes.fetch(journable_type) do
      journal_class = journable_type.constantize.journal_class
      [journal_class.to_s, journal_class.table_name]
    end
  end

  def unmigratable_journal_classes
    {
      "WikiContent" => %w[Journal::WikiContentJournal wiki_content_journals]
    }
  end

  def take_over_from_successor(journal)
    # The successors may also have their data deleted.
    # in this case, look for the first journal with data. If non can be found, instantiate from the journaled object.
    first_journal_with_data = journal.journable.journals.detect { |j| j.data.present? }

    if first_journal_with_data.nil?
      insert_journal_data(journal, write_message: true)
    else
      take_over_from_source(journal, first_journal_with_data)
    end
  end

  def take_over_from_source(journal, source)
    raise "Related journal does not have data, this shouldn't be!" if source.data.nil?

    new_data = source.data.dup
    new_data.save!

    update_with_new_data!(journal, new_data.id)
  end

  def update_with_new_data!(journal, data_id)
    notes = journal.notes || ""
    notes << "\n" unless notes.empty?
    notes << "_(This activity had to be modified by the system and may be missing some changes or contain changes from previous or following activities.)_"

    journal.update_columns(notes:, data_id:)
  end
end
