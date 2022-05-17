class ReorderProjectChildren < ActiveRecord::Migration[6.1]
  def up
    ::Projects::ReorderHierarchyJob.perform_later
  end
end
