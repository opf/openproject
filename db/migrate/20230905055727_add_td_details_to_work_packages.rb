class AddTdDetailsToWorkPackages < ActiveRecord::Migration[7.0]
  def change
    add_column :work_packages, :td_severity_value, :integer, default: 1
    add_column :work_packages, :td_labour_rate, :float, default: 75
    add_column :work_packages, :td_estimated_time, :float, default: 1
    add_column :work_packages, :td_payback_likelihood, :float
    add_column :work_packages, :td_principal, :float
  end
end
