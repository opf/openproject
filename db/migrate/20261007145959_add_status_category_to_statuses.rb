# frozen_string_literal: true

class AddStatusCategoryToStatuses < ActiveRecord::Migration[8.1]
  def up
    add_column :statuses, :category, :string

    execute <<~SQL.squish
      UPDATE statuses SET category = 'closed'
      WHERE statuses.is_closed = true;
    SQL

    remove_column :statuses, :is_closed
    add_index :statuses, :category, name: "index_statuses_on_category"
  end

  def down
    add_column :statuses, :is_closed, :boolean, default: false, null: false

    execute <<~SQL.squish
      UPDATE statuses SET is_closed = true
      WHERE statuses.category = 'closed';
    SQL

    remove_column :statuses, :category
    add_index :statuses, :is_closed, name: "index_statuses_on_is_closed"
  end
end
