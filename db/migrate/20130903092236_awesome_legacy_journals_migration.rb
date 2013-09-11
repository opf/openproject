class AwesomeLegacyJournalsMigration < ActiveRecord::Migration

  class UnsupportedWikiContentJournalCompressionError < ::StandardError
  end

  class AmbiguousJournalsError < ::StandardError
  end

  class AmbiguousAttachableJournalError < AmbiguousJournalsError
  end

  class AmbiguousCustomizableJournalError < AmbiguousJournalsError
  end

  class IncompleteJournalsError < ::StandardError
  end

  class LegacyJournalMigrator
    attr_accessor :table_name

    def initialize(table_name)
      self.table_name = table_name
    end

    def column_names
      @column_names ||= ActiveRecord::Base.connection.columns(table_name).map(&:name)
    end
  end

  def up
    check_assumptions

    previous_journaled_id, previous_type = 0, ""
    previous_journal = {}
    journal_classes = {
      "AttachmentJournal" => LegacyJournalMigrator.new("attachment_journals"),
      "ChangesetJournal" => LegacyJournalMigrator.new("changeset_journals"),
      "NewsJournal" => LegacyJournalMigrator.new("news_journals"),
      "MessageJournal" => LegacyJournalMigrator.new("message_journals"),
      "WorkPackageJournal" => LegacyJournalMigrator.new("work_package_journals"),
      "TimeEntryJournal" => LegacyJournalMigrator.new("time_entry_journals"),
      "WikiContentJournal" => LegacyJournalMigrator.new("wiki_content_journals")
    }

    fetch_legacy_journals.each do |legacy_journal|

      # turn id fields into integers.
      ["id", "journaled_id", "user_id", "version"].each do |f|
        legacy_journal[f] = legacy_journal[f].to_i
      end

      legacy_journal["changed_data"] = YAML.load(legacy_journal["changed_data"])

      journaled_id, type, version = legacy_journal["journaled_id"], legacy_journal["type"], legacy_journal["version"]
      table = journal_tables[type]

      if table.nil?
        puts "Ignoring type `#{type}`"
        next
      end

      # actually insert/update stuff in the database.
      journal = get_journal(journaled_id, type, version)
      journal_id = journal["id"]

      # compute the combined journal from current and all previous changesets.
      combined_journal = legacy_journal["changed_data"]
      if previous_journaled_id == journaled_id && previous_type == type
        combined_journal = previous_journal.merge(combined_journal)
      end

      # remember the combined journal as the previous one for the next iteration.
      previous_journal = combined_journal
      previous_journaled_id = journaled_id
      previous_type = type

      data = fetch_journal_data(journal_id, table)

      to_insert = combined_journal.inject({}) do |mem, (key, value)|
        if journal_class.column_names.include?(key)
          # The old journal's values attribute was structured like
          # [old_value, new_value]
          # We only need the new_value
          mem[key] = value.last
        end

        mem
      end

      keys = to_insert.keys
      values = to_insert.values

      migrate_key_value_pairs!(keys, values, table, legacy_journal, journal_id)

      if data.size > 1

        raise AmbiguousJournalsError, <<-MESSAGE.split("\n").map(&:strip!).join(" ") + "\n"
          It appears there are ambiguous journal data. Please make sure
          journal data are consistent and that the unique constraint on
          journal_id is met.
        MESSAGE

      elsif data.size == 0
        execute <<-SQL
          INSERT INTO #{quoted_table_name(table)} (journal_id#{", " + keys.collect{|k| map_key(k) }.join(", ") unless keys.empty? })
          VALUES (#{quote_value(journal_id)}#{", " + values.map{|d| quote_value(d)}.join(", ") unless values.empty?});
        SQL

        data = fetch_journal_data(journal_id, table)
      end

      data = data.first

      sql_statements = <<-SQL
        UPDATE journals
           SET journable_data_id   = #{quote_value(journal_id)},
               journable_data_type = #{quote_value(type)},
               user_id             = #{quote_value(legacy_journal["user_id"])},
               notes               = #{quote_value(legacy_journal["notes"])},
               created_at          = #{quote_value(legacy_journal["created_at"])},
               activity_type       = #{quote_value(legacy_journal["activity_type"])}
         WHERE id = #{quote_value(journal_id)};
      SQL

      sql_statements = <<-SQL + sql_statements unless keys.empty?
        UPDATE #{quoted_table_name(table)}
           SET #{(keys.each_with_index.map {|k,i| "#{map_key(k)} = #{quote_value(values[i])}"}).join(", ")}
         WHERE id = #{data["id"]};
      SQL

      execute sql_statements

    end

  end

  def down
  end

  private

  def map_key(key)
    case key
    when "issue_id"
      "work_package_id"
    else
      key
    end
  end

  def migrate_key_value_pairs!(keys, values, table, legacy_journal, journal_id)
    migrate_key_value_pairs_for_wiki_contents!(keys, values, table, legacy_journal, journal_id)
    migrate_key_value_pairs_for_work_packages!(keys, values, table, legacy_journal, journal_id)
  end

  def migrate_key_value_pairs_for_work_packages!(keys, values, table, legacy_journal, journal_id)

    if table == "work_package_journals"

      attachments = keys.select { |d| d =~ /attachments_.*/ }
      attachments.each do |k|

        attachment_id = k.split("_").last.to_i

        attachable = ActiveRecord::Base.connection.select_all <<-SQL
          SELECT *
          FROM #{quoted_table_name("attachable_journals")} AS a
          WHERE a.journal_id = #{quote_value(journal_id)} AND a.attachment_id = #{attachment_id};
        SQL

        if attachable.size > 1

          raise AmbiguousAttachableJournalError, <<-MESSAGE.split("\n").map(&:strip!).join(" ") + "\n"
            It appears there are ambiguous attachable journal data.
            Please make sure attachable journal data are consistent and
            that the unique constraint on journal_id and attachment_id
            is met.
          MESSAGE

        elsif attachable.size == 0

          execute <<-SQL
            INSERT INTO #{quoted_table_name("attachable_journals")}(journal_id, attachment_id)
            VALUES (#{quote_value(journal_id)}, #{quote_value(attachment_id)});
          SQL
        end

        j = keys.index(k)
        [keys, values].each { |a| a.delete_at(j) }
      end

      custom_values = keys.select { |d| d =~ /custom_values.*/ }
      custom_values.each do |k|

        custom_field_id = k.split("_values").last.to_i
        value = values[keys.index k]

        customizable = ActiveRecord::Base.connection.select_all <<-SQL
          SELECT *
          FROM #{quoted_table_name("customizable_journals")} AS a
          WHERE a.journal_id = #{quote_value(journal_id)} AND a.custom_field_id = #{custom_field_id};
        SQL

        if customizable.size > 1

          raise AmbiguousCustomizableJournalError, <<-MESSAGE.split("\n").map(&:strip!).join(" ") + "\n"
            It appears there are ambiguous customizable journal
            data. Please make sure customizable journal data are
            consistent and that the unique constraint on journal_id and
            custom_field_id is met.
          MESSAGE

        elsif customizable.size == 0

          execute <<-SQL
            INSERT INTO #{quoted_table_name("customizable_journals")}(journal_id, custom_field_id, value)
            VALUES (#{quote_value(journal_id)}, #{quote_value(custom_field_id)}, #{quote_value(value)});
          SQL
        end

        j = keys.index(k)
        [keys, values].each { |a| a.delete_at(j) }

      end
    end
  end

  # custom logic for changes wiki contents.
  def migrate_key_value_pairs_for_wiki_contents!(keys, values, table, legacy_journal, journal_id)

    if table == "wiki_content_journals"

      if keys.index("lock_version").nil?
        keys.push "lock_version"
        values.push legacy_journal["version"]
      end

      if !(data_index = keys.index("data")).nil?

        compression_index = keys.index("compression")
        compression = values[compression_index]

        if !compression.empty?

          raise UnsupportedWikiContentJournalCompressionError, <<-MESSAGE.split("\n").map(&:strip!).join(" ") + "\n"
            There is a WikiContent journal that contains data in an
            unsupported compression: #{compression}
          MESSAGE

        end

        keys[data_index] = "text"

        keys.delete_at(compression_index)
        values.delete_at(compression_index)
      end

    end
  end

  # fetches specific journal data row. might be empty.
  def fetch_journal_data(journal_id, table)
    ActiveRecord::Base.connection.select_all <<-SQL
      SELECT *
      FROM #{quoted_table_name(table)} AS d
      WHERE d.journal_id = #{quote_value(journal_id)};
    SQL
  end

  # gets a journal row, and makes sure it has a valid id in the database.
  def get_journal(id, type, version)
    journal = fetch_journal(id, type, version)

    if journal.size > 1

      raise AmbiguousJournalsError, <<-MESSAGE.split("\n").map(&:strip!).join(" ") + "\n"
        It appears there are ambiguous journals. Please make sure
        journals are consistent and that the unique constraint on id,
        type and version is met.
      MESSAGE

    elsif journal.size == 0

      execute <<-SQL
        INSERT INTO #{quoted_journals_table_name}(journable_id, journable_type, version, created_at)
        VALUES (
          #{quote_value(id)},
          #{quote_value(type)},
          #{quote_value(version)},
          #{quote_value(Time.now)}
        );
      SQL

      journal = fetch_journal(id, type, version)
    end

    journal.first
  end

  # fetches specific journal row. might be empty.
  def fetch_journal(id, type, version)
    ActiveRecord::Base.connection.select_all <<-SQL
      SELECT *
      FROM #{quoted_journals_table_name} AS j
      WHERE j.journable_id = #{quote_value(id)}
        AND j.journable_type = #{quote_value(type)}
        AND j.version = #{quote_value(version)};
    SQL
  end

  # fetches legacy journals. might me empty.
  def fetch_legacy_journals

    attachments_and_changesets = ActiveRecord::Base.connection.select_all <<-SQL
      SELECT *
      FROM #{quoted_legacy_journals_table_name} AS j
      WHERE (j.activity_type = #{quote_value("attachments")})
        OR (j.activity_type = #{quote_value("custom_fields")})
      ORDER BY j.journaled_id, j.activity_type, j.version;
    SQL

    remainder = ActiveRecord::Base.connection.select_all <<-SQL
      SELECT *
      FROM #{quoted_legacy_journals_table_name} AS j
      WHERE NOT ((j.activity_type = #{quote_value("attachments")})
        OR (j.activity_type = #{quote_value("custom_fields")}))
      ORDER BY j.journaled_id, j.activity_type, j.version;
    SQL

    attachments_and_changesets + remainder
  end


  def quote_value name
    ActiveRecord::Base.connection.quote name
  end

  def quoted_table_name name
    ActiveRecord::Base.connection.quote_table_name name
  end

  def quoted_legacy_journals_table_name
    @@quoted_legacy_journals_table_name ||= quote_table_name 'legacy_journals'
  end

  def quoted_journals_table_name
    @@quoted_journals_table_name ||= quote_table_name 'journals'
  end

  def check_assumptions

    invalid_journals = ActiveRecord::Base.connection.select_values <<-SQL
      SELECT DISTINCT tmp.id
      FROM (
        SELECT
          a.id AS id,
          a.journaled_id,
          a.type,
          a.version AS version,
          count(b.id) AS count
        FROM
          #{quoted_legacy_journals_table_name} AS a
        LEFT JOIN
          #{quoted_legacy_journals_table_name} AS b
          ON a.version >= b.version
            AND a.journaled_id = b.journaled_id
            AND a.type = b.type
        WHERE a.version > 1
        GROUP BY
          a.id,
          a.journaled_id,
          a.type,
          a.version
      ) AS tmp
      WHERE
        NOT (tmp.version = tmp.count);
    SQL

    unless invalid_journals.empty?

      raise IncompleteJournalsError, <<-MESSAGE.split("\n").map(&:strip!).join(" ") + "\n"
        It appears there are incomplete journals. Please make sure
        journals are consistent and that for every journal, there is an
        initial journal containing all attribute values at the time of
        creation. The offending journal ids are: #{invalid_journals}
      MESSAGE
    end
  end

end
