class AddCustomActions < ActiveRecord::Migration[5.0]
  def change
    create_table :custom_actions do |t|
      t.string :name
      t.text :actions
    end

    create_table :custom_actions_statuses do |t|
      t.belongs_to :status
      t.belongs_to :custom_action
    end

    create_table :custom_actions_roles do |t|
      t.belongs_to :role
      t.belongs_to :custom_action
    end

    create_table :custom_actions_types do |t|
      t.belongs_to :type
      t.belongs_to :custom_action
    end

    create_table :custom_actions_projects do |t|
      t.belongs_to :project
      t.belongs_to :custom_action
    end
  end
end
