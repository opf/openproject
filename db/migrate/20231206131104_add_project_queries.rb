class AddProjectQueries < ActiveRecord::Migration[7.0]
  def change
    create_table :project_queries do |t|
      t.string :name, null: false
      t.text :filters
      t.references :user, null: false
      t.boolean :public, default: false, null: false
      t.json :columns
      t.json :orders
      t.string :group_by
      t.boolean :display_sums, default: false, null: false
    end
  end
end
