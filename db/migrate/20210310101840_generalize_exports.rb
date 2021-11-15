class GeneralizeExports < ActiveRecord::Migration[6.1]
  def change
    rename_table :work_package_exports, :exports

    change_table :exports do |t|
      t.string :type
    end

    reversible do |dir|
      dir.up do
        execute "UPDATE exports SET type = 'WorkPackages::Export'"
      end
    end
  end
end
