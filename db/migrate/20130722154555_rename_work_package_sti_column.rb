class RenameWorkPackageStiColumn < ActiveRecord::Migration
  def up
    rename_column :work_packages, :type, :sti_type
  end

  def down
    rename_column :work_packages, :sti_type, :type
  end
end
