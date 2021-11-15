class AddWorkPackageExports < ActiveRecord::Migration[6.0]
  def change
    create_table :work_package_exports do |t|
      t.references :user

      t.timestamps
    end
  end
end
