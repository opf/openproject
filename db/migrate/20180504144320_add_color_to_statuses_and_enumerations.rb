class AddColorToStatusesAndEnumerations < ActiveRecord::Migration[5.1]
  def change
    change_table :statuses do |t|
      t.belongs_to :color, type: :int
    end

    change_table :enumerations do |t|
      t.belongs_to :color, type: :int
    end
  end
end
