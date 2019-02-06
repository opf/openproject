class CreateOrderedWorkPackages < ActiveRecord::Migration[5.1]
  def change
    create_table :ordered_work_packages do |t|
      t.integer    :position, index: true, null: false
      
      t.references :query, type: :integer, foreign_key: { index: true, on_delete: :cascade }
      t.references :work_package, type: :integer, foreign_key: { index: true, on_delete: :cascade }
    end
  end
end
