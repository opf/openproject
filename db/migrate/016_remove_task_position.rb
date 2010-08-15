class RemoveTaskPosition < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      Task.find(:all, :conditions => "id <> root_id and not position is null").each do |t|
        t.remove_from_list
      end
    end
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
