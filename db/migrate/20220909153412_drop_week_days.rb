class DropWeekDays < ActiveRecord::Migration[7.0]
  def up
    drop_table :week_days
  end

  def down
    create_table :week_days do |t|
      t.integer :day, null: false
      t.boolean :working, null: false, default: true

      t.timestamps
    end

    execute <<-SQL.squish
        ALTER TABLE week_days
          ADD CONSTRAINT unique_day_number UNIQUE (day);
        ALTER TABLE week_days
          ADD CHECK (day >= 1 AND day <=7);
    SQL
  end
end
