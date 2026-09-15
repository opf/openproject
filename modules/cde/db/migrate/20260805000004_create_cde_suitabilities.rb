# frozen_string_literal: true

class CreateCdeSuitabilities < ActiveRecord::Migration[7.0]
  def change
    create_table :cde_suitabilities do |t|
      t.references :container, null: false, foreign_key: { to_table: :cde_containers }, index: true
      t.references :assigner, foreign_key: { to_table: :users }
      t.integer :code, null: false, default: 0
      t.text :reason
      t.timestamps
    end

    add_index :cde_suitabilities, [:container_id, :code], unique: true
    add_index :cde_suitabilities, :code
  end
end
