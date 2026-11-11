# frozen_string_literal: true

class AddOptionsToJiras < ActiveRecord::Migration[8.1]
  def change
    add_column :jiras, :options, :jsonb, default: {}, null: false
  end
end
