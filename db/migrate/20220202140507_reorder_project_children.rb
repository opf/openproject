class ReorderProjectChildren < ActiveRecord::Migration[6.1]
  def up
    ::Projects::ReorderChildrenJob.perform_later
  end
end
