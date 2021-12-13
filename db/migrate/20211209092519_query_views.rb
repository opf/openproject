class QueryViews < ActiveRecord::Migration[6.1]
  def up
    add_column :queries,
               :starred,
               :boolean,
               default: false

    # Some older queries seem to lack values for created_at and updated_at. Taking NOW which is better than NULL.
    execute <<~SQL.squish
      UPDATE
        queries
      SET
        created_at = NOW()
      WHERE
        created_at IS NULL
    SQL

    execute <<~SQL.squish
      UPDATE
        queries
      SET
        updated_at = NOW()
      WHERE
        updated_at IS NULL
    SQL

    execute <<~SQL.squish
      INSERT INTO
        views (
          type,
          query_id,
          created_at,
          updated_at
        )
      SELECT
        'work_packages_table',
        id,
        created_at,
        updated_at
      FROM queries
      WHERE
        hidden = false
    SQL

    execute <<~SQL.squish
      UPDATE
        queries
      SET
        starred = true
      WHERE
        id IN (SELECT navigatable_id FROM menu_items WHERE type = 'MenuItems::QueryMenuItem')
    SQL

    execute <<~SQL.squish
      DELETE FROM
        menu_items
      WHERE
        type = 'MenuItems::QueryMenuItem'
    SQL

    remove_column :queries,
                  :hidden

    rename_column :queries,
                  :is_public,
                  :public
  end

  def down
    rename_column :queries,
                  :public,
                  :is_public

    add_column :queries,
               :hidden,
               :boolean,
               default: false

    # Consciously avoiding the use of a PostgreSQL 13.0 feature (gen_random_uuid())
    Query.where(starred: true).find_each do |query|
      execute <<~SQL.squish
        INSERT INTO
          menu_items (
           type,
           navigatable_id,
           name,
           title
        ) VALUES (
          'MenuItems::QueryMenuItem',
          #{query.id},
          '#{SecureRandom.uuid}',
          '#{query.name}'
        )
      SQL
    end

    execute <<~SQL.squish
      UPDATE
        queries
      SET
        hidden = true
      WHERE
        id NOT IN (SELECT query_id FROM views WHERE type = 'work_packages_table')
    SQL

    execute <<~SQL.squish
      DELETE FROM
        views
      WHERE type = 'work_packages_table'
    SQL

    remove_column :queries,
                  :starred
  end
end
