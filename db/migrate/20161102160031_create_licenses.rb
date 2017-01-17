class CreateLicenses < ActiveRecord::Migration[5.0]
  def change
    create_table :licenses do |t|
      t.text :encoded_license

      t.timestamps
    end
  end
end
