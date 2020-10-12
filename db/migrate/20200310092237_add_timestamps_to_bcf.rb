class AddTimestampsToBcf < ActiveRecord::Migration[6.0]
  def change
    add_timestamps :bcf_issues, default: DateTime.now
    add_timestamps :bcf_viewpoints, default: DateTime.now
  end
end
