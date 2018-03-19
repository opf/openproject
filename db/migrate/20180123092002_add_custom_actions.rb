class AddCustomActions < ActiveRecord::Migration[5.1]
  def change
    create_table :custom_actions, id: :integer do |t|
      t.string :name
      t.text :actions
    end

    create_table :custom_actions_statuses, id: :integer do |t|
      t.belongs_to :status
      t.belongs_to :custom_action
    end

    create_table :custom_actions_roles, id: :integer do |t|
      t.belongs_to :role
      t.belongs_to :custom_action
    end

    create_table :custom_actions_types, id: :integer do |t|
      t.belongs_to :type
      t.belongs_to :custom_action
    end

    create_table :custom_actions_projects, id: :integer do |t|
      t.belongs_to :project
      t.belongs_to :custom_action
    end
  end
end
