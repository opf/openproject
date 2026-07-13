# frozen_string_literal: true

class AddUniqueIndexToUserWorkingHoursValidFrom < ActiveRecord::Migration[8.1]
  def change
    add_index :user_working_hours, %i[user_id valid_from], unique: true
  end
end
