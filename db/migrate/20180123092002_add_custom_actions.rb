class AddCustomActions < ActiveRecord::Migration[5.0]
  def change
    create_table :custom_actions do |t|
      t.string :name
      t.text :actions
    end
  end
end
