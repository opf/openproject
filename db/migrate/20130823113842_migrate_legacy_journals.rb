class MigrateLegacyJournals < ActiveRecord::Migration

  class AmbiguousJournalsError < ::StandardError
  end

  class IncompleteJournalsError < ::StandardError
  end

  def up
    check_assumptions

    fetch_legacy_journals.each do |journal|

      # turn id fields into integers.
      ["id", "journaled_id", "user_id", "version"].each do |f|
        journal[f] = journal[f].to_i
      end

      journal["changed_data"] = YAML.load(journal["changed_data"])

      get_journal journal["journaled_id"],
                  journal["type"],
                  journal["version"]
    end

    binding.pry

  end

  def down
  end

  private

  # gets a journal, and makes sure it has a valid id in the database.
  def get_journal(id, type, version)
    journal = fetch_journal(id, type, version)

    if journal.size > 1

      raise AmbiguousJournalsError, <<-MESSAGE.split("\n").map(&:strip!).join(" ") + "\n"
        It appears there are ambiguous journals. Please make sure
        journals are consistent and that the unique constraing on id,
        type and version is met.
      MESSAGE

    elsif journal.size == 0

      execute <<-SQL
        INSERT INTO journals(journable_id, journable_type, version, created_at)
        VALUES (
          #{quote_value(id)},
          #{quote_value(type)},
          #{quote_value(version)},
          #{quote_value(Time.now)}
        )
      SQL
    end

    journal || fetch_journal(id, type, version)
  end

  # fetches legacy journals. might me empty.
  def fetch_legacy_journals
    ActiveRecord::Base.connection.select_all <<-SQL
      SELECT *
      FROM #{quoted_legacy_journals_table_name} AS j
      ORDER BY j.journaled_id, j.activity_type, j.version
    SQL
  end

  # fetches specific journal. might be empty.
  def fetch_journal(id, type, version)
    ActiveRecord::Base.connection.select_all <<-SQL
      SELECT *
      FROM #{quoted_journals_table_name} AS j
      WHERE j.journable_id = #{quote_value(id)}
        AND j.journable_type = #{quote_value(type)}
        AND j.version = #{quote_value(version)}
    SQL
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
          a.id AS id, a.journaled_id, a.activity_type,
          a.version AS version, count(b.id) AS count
        FROM
          #{quoted_legacy_journals_table_name} AS a
        LEFT JOIN
          #{quoted_legacy_journals_table_name} AS b
          ON a.version >= b.version
            AND a.journaled_id = b.journaled_id
            AND a.activity_type = b.activity_type
        WHERE a.version > 1
        GROUP BY a.id
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
