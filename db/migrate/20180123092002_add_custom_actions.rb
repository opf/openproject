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
  end
end
