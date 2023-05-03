class FillProjectJournalsWithExistingData < ActiveRecord::Migration[7.0]
  def up
    make_sure_journals_notes_is_nullable
    # On some user instances, invalid custom values were encountered. Those
    # custom_values belonged to projects which had been deleted in the meantime.
    delete_invalid_custom_values
    create_journal_entries_for_projects
  end

  def down
    delete_journal_entries_for_projects
  end

  private

  def make_sure_journals_notes_is_nullable
    change_column_null(:journals, :notes, true)
  end

  def create_journal_entries_for_projects
    sql = <<~SQL.squish
      WITH project_journals_insertion AS (
        INSERT INTO project_journals(
            name,
            description,
            public,
            parent_id,
            identifier,
            active,
            templated
          )
        SELECT name,
          description,
          public,
          parent_id,
          identifier,
          active,
          templated
        FROM projects
        RETURNING id,
          identifier
      ),
      journals_insertion AS (
        INSERT into journals (
            journable_id,
            journable_type,
            user_id,
            created_at,
            updated_at,
            version,
            data_type,
            data_id
          )
        SELECT projects.id,
          'Project',
          :user_id,
          projects.created_at,
          projects.updated_at,
          1,
          'Journal::ProjectJournal',
          project_journals_insertion.id
        FROM projects
          FULL JOIN project_journals_insertion ON projects.identifier = project_journals_insertion.identifier
        RETURNING id,
          journable_id
      ),
      customizable_journals_insertion AS (
        INSERT into customizable_journals (
            journal_id,
            custom_field_id,
            value
          )
        SELECT journals_insertion.id,
          custom_field_id,
          value
        FROM custom_values
          FULL JOIN journals_insertion ON custom_values.customized_id = journals_insertion.journable_id
        WHERE custom_values.customized_type = 'Project'
      )
      SELECT COUNT(1)
      FROM journals_insertion;
    SQL
    sql = ::ActiveRecord::Base.sanitize_sql_array([sql, { user_id: User.system.id }])
    execute(sql)
  end

  def delete_journal_entries_for_projects
    execute(<<~SQL.squish)
      DELETE
      FROM customizable_journals
      WHERE journal_id IN (
        SELECT id FROM journals WHERE journable_type = 'Project'
      )
    SQL
    execute(<<~SQL.squish)
      DELETE
      FROM journals
      WHERE journable_type = 'Project'
    SQL
    execute(<<~SQL.squish)
      DELETE
      FROM project_journals
    SQL
  end

  def delete_invalid_custom_values
    execute(<<~SQL.squish)
      DELETE
      FROM
        custom_values
      WHERE
        custom_values.customized_type = 'Project'
        AND NOT EXISTS (SELECT 1 FROM projects WHERE projects.id = custom_values.customized_id)
    SQL
  end
end
