class AddPositionToCustomAction < ActiveRecord::Migration[5.0]
  def change
    add_column :custom_actions, :position, :integer

    reversible do |dir|
      dir.up do
        CustomAction.order_by_name.each_with_index do |a, i|
          a.update_attribute(:position, i)
        end
      end
    end
  end
end
