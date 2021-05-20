class MakeProjectIdentifierUnique < ActiveRecord::Migration[6.1]
  def change
    remove_index :projects, :identifier

    begin
      add_index :projects, :identifier, unique: true
    rescue => e
      raise "You have a duplicate project identifier in your database: #{e.message}"
    end
  end
end
