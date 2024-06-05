class CreateDeployTargets < ActiveRecord::Migration[7.1]
  def change
    create_table :deploy_targets do |t|
      t.text :type, null: false
      t.text :host, null: false
      t.jsonb :options, null: false, default: {}

      t.timestamps
    end

    add_index :deploy_targets, :host, unique: true
  end
end
