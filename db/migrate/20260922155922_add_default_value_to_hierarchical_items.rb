# frozen_string_literal: true

class AddDefaultValueToHierarchicalItems < ActiveRecord::Migration[8.1]
  def change
    add_column :hierarchical_items, :default_value, :boolean, null: false, default: false
  end
end
