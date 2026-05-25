# frozen_string_literal: true

class CreateMngtProjectAPIIds < ActiveRecord::Migration[7.1]
  def change
    create_table :mngt_project_api_ids do |t|
      t.references :project, null: false, foreign_key: true, index: { unique: true }
      t.string :api_company_id
      t.string :api_area_id
      t.string :api_sector_id
      t.timestamps
    end

    add_index :mngt_project_api_ids,
              %i[api_company_id api_area_id api_sector_id],
              name: "index_mngt_project_api_ids_on_triple"
  end
end
