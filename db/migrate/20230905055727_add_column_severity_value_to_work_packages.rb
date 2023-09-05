class AddColumnSeverityValueToWorkPackages < ActiveRecord::Migration[7.0]
  def change
    add_column :work_packages, :severity_value, :integer, default: 1
  end
end
