class AddProjectQueries < ActiveRecord::Migration[7.0]
  def change
    create_table :project_queries do |t|
      t.string :name, null: false
      t.references :user, null: false
      t.json :filters, default: []
      t.json :columns, default: []
      t.json :orders, default: []

      t.timestamps
    end
  end
end
