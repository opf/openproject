class CreateCustomStyles < ActiveRecord::Migration[5.0]
  def change
    create_table :custom_styles do |t|
      t.string :logo

      t.timestamps
    end
  end
end
