require_relative './migration_utils/utils'

class AddJournalVersionsTable < ActiveRecord::Migration[5.2]
  include ::Migration::Utils

  def up
    create_table :journal_versions do |t|
      t.string :journable_type
      t.integer :journable_id
      t.integer :version, default: 0
      t.index %i[journable_type journable_id version],
              name: 'unique_journal_version',
              unique: true
    end

    ActiveRecord::Base.connection.execute <<-SQL
          INSERT INTO journal_versions (journable_type, journable_id, version)
          (SELECT
            journable_type, journable_id, MAX(version)
          FROM journals
          GROUP BY journable_type, journable_id);
    SQL
  end

  def down
    drop_table :journal_versions
  end
end
