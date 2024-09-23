class CreateDeployStatusChecks < ActiveRecord::Migration[7.1]
  def change
    create_table :deploy_status_checks do |t|
      t.references :deploy_target
      t.references :github_pull_request

      t.text :core_sha, null: false

      t.timestamps
    end
  end
end
