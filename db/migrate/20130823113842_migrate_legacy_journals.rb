class MigrateLegacyJournals < ActiveRecord::Migration

  class IncompleteJournalsError < ::StandardError
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

  def up
    check_assumptions
    binding.pry
  end

  def down
  end

  def quoted_legacy_journals_table_name
    ActiveRecord::Base.connection.quote_table_name('legacy_journals')
  end

end
