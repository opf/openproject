# frozen_string_literal: true

class AddVisibleOnUserCardToCustomFields < ActiveRecord::Migration[8.1]
  def change
    add_column :custom_fields, :visible_on_user_card, :boolean, null: false, default: false
  end
end
