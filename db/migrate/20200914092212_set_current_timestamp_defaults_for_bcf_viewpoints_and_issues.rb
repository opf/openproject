class SetCurrentTimestampDefaultsForBcfViewpointsAndIssues < ActiveRecord::Migration[6.0]
  def up
    change_column_default(:bcf_issues, :created_at, -> { 'CURRENT_TIMESTAMP' })
    change_column_default(:bcf_issues, :updated_at, -> { 'CURRENT_TIMESTAMP' })
    change_column_default(:bcf_viewpoints, :created_at, -> { 'CURRENT_TIMESTAMP' })
    change_column_default(:bcf_viewpoints, :updated_at, -> { 'CURRENT_TIMESTAMP' })
  end

  def down
    # Nothing to do.
  end
end
