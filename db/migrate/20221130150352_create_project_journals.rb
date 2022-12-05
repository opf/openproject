class CreateProjectJournals < ActiveRecord::Migration[7.0]
  # rubocop:disable Rails/CreateTableWithTimestamps(RuboCop)
  def change
    create_table :project_journals do |t|
      t.string :name, null: false
      t.text :description
      t.boolean :public, null: false
      t.bigint :parent_id
      t.string :identifier, null: false
      t.boolean :active, null: false
      t.boolean :templated, null: false
    end
  end
  # rubocop:enable Rails/CreateTableWithTimestamps(RuboCop)
end
