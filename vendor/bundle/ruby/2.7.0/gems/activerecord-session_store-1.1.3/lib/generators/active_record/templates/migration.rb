class <%= migration_class_name %> < ActiveRecord::Migration<%= migration_version %>
  def change
    create_table :<%= session_table_name %> do |t|
      t.string :session_id, :null => false
      t.text :data
      t.timestamps
    end

    add_index :<%= session_table_name %>, :session_id, :unique => true
    add_index :<%= session_table_name %>, :updated_at
  end
end
