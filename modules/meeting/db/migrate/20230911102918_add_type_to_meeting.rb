class AddTypeToMeeting < ActiveRecord::Migration[7.0]
  def change
    add_column :meetings, :type, :string, default: 'Meeting', null: false
  end
end
