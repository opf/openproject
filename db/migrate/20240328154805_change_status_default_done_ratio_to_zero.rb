class ChangeStatusDefaultDoneRatioToZero < ActiveRecord::Migration[7.1]
  def change
    change_column_default :statuses, :default_done_ratio, from: nil, to: 0
    reversible do |dir|
      dir.up do
        execute "UPDATE statuses SET default_done_ratio = 0 WHERE default_done_ratio IS NULL"
      end
    end
    change_column_null :statuses, :default_done_ratio, false
  end
end
