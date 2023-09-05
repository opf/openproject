class AddDetailsToWorkPackages < ActiveRecord::Migration[7.0]
  def change
    add_column :work_packages, :td_principal, :float
    add_column :work_packages, :ticket_id, :integer
  end
end
