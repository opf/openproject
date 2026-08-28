# frozen_string_literal: true

class AddRiskManagementCoreAttributes < ActiveRecord::Migration[8.0]
  def change
    add_column :types, :builtin_identifier, :string
    add_index :types, :builtin_identifier, unique: true

    create_risk_categories
    add_risk_attributes
    add_risk_journal_attributes
    create_risk_management_plans
  end

  private

  def create_risk_categories
    create_table :risk_categories do |t|
      t.string :name, null: false
      t.references :color, foreign_key: true
      t.integer :position, null: false, default: 1
      t.boolean :active, null: false, default: true
      t.timestamps
    end
    add_index :risk_categories, :name, unique: true
  end

  def add_risk_attributes
    change_table :work_packages, bulk: true do |t|
      t.references :risk_owner, foreign_key: { to_table: :users }
      t.decimal :risk_likelihood, precision: 5, scale: 2
      t.decimal :risk_impact, precision: 20, scale: 2
      t.string :risk_response
      t.bigint :risk_category_ids, array: true, default: [], null: false
    end
  end

  def add_risk_journal_attributes
    change_table :work_package_journals, bulk: true do |t|
      t.references :risk_owner
      t.decimal :risk_likelihood, precision: 5, scale: 2
      t.decimal :risk_impact, precision: 20, scale: 2
      t.string :risk_response
      t.bigint :risk_category_ids, array: true, default: [], null: false
    end
  end

  def create_risk_management_plans
    create_table :risk_management_plans do |t|
      t.references :project, null: false, foreign_key: { on_delete: :cascade }, index: { unique: true }
      t.text :body, null: false, default: ""
      t.references :author, null: false, foreign_key: { to_table: :users }
      t.references :updated_by, null: false, foreign_key: { to_table: :users }
      t.integer :lock_version, null: false, default: 0
      t.timestamps
    end
  end
end
