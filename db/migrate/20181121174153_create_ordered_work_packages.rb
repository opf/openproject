class CreateOrderedWorkPackages < ActiveRecord::Migration[5.1]
  def change
    create_table :ordered_work_packages do |t|
      t.integer    :position, index: true
      t.references :query, foreign_key: true
      t.references :work_package, foreign_key: true

      t.timestamps
    end
  end
end
