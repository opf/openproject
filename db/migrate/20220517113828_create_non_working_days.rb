class CreateNonWorkingDays < ActiveRecord::Migration[6.1]
  def change
    create_table :non_working_days do |t|
      t.string :name, null: false
      t.date :date, null: false

      t.timestamps
    end
    add_index :non_working_days, :date, unique: true
  end
end
