# frozen_string_literal: true

class AddOriginColumnsToWorkPackages < ActiveRecord::Migration[7.1]
  def change
    change_table :work_packages, bulk: true do |t|
      t.string :origin_source, null: true
      t.string :origin_id, null: true
      t.string :origin_url, null: true
      t.string :origin_host, null: true
    end
  end
end
