class RenameCostObjectType < ActiveRecord::Migration[6.1]
  def up
    Journal
      .where(journable_type: 'CostObject')
      .update_all(journable_type: 'Budget')
  end

  def down
    # Doesn't need to be reverted
  end
end
