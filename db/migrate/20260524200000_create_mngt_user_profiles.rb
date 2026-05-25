# frozen_string_literal: true

class CreateMngtUserProfiles < ActiveRecord::Migration[7.1]
  def change
    create_table :mngt_user_profiles do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.string :company_slug, null: false
      t.timestamps
    end
  end
end
