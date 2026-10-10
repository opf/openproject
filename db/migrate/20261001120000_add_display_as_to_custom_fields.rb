# frozen_string_literal: true

class AddDisplayAsToCustomFields < ActiveRecord::Migration[8.1]
  def change
    add_column :custom_fields, :display_as, :string, null: true
  end
end
