# frozen_string_literal: true

class AddGroupDetailIndexForOus < ActiveRecord::Migration[8.1]
  def change
    add_index :group_details, :organizational_unit
  end
end
