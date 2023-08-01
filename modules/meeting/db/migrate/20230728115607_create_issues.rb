class CreateIssues < ActiveRecord::Migration[5.1]
  def change
    create_table :issues do |t|
      t.references :work_package
      t.references :author, foreign_key: { to_table: :users }
      t.references :resolved_by, foreign_key: { to_table: :users }, null: true
      t.integer :issue_type, default: 0, null: false
      t.text :description
      t.text :resolution
      t.datetime :resolved_at

      t.timestamps
    end
  end
end
