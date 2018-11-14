class AddWebhooks < ActiveRecord::Migration[5.0]
  def change
    create_table :webhooks_webhooks do |t|
      t.string :name
      t.text :url
      t.text :description, null: false
      t.string :secret, null: true
      t.boolean :enabled, null: false
      t.boolean :all_projects, null: false

      t.timestamps
    end

    create_table :webhooks_events do |t|
      t.string :name
      t.references :webhooks_webhook, index: true, foreign_key: true
    end

    create_table :webhooks_projects do |t|
      t.references :project, index: true, foreign_key: true
      t.references :webhooks_webhook, index: true, foreign_key: true
    end
  end
end
