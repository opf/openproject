class CreateCustomStyles < ActiveRecord::Migration[5.1]
  def change
    create_table :custom_styles, id: :integer do |t|
      t.string :logo

      t.timestamps
    end
  end
end
