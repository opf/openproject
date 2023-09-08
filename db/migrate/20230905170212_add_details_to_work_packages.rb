class AddDetailsToWorkPackages < ActiveRecord::Migration[7.0]
  def change
    add_column :work_packages, :td_principal, :float
  end
end
