class CreateWebhookLogs < ActiveRecord::Migration[5.0]
  def change
    create_table :webhooks_logs do |t|
      t.references :webhooks_webhook, foreign_key: { on_delete: :cascade }

      t.string :event_name
      t.string :url

      t.text :request_headers
      t.text :request_body

      t.integer :response_code
      t.text :response_headers
      t.text :response_body

      t.timestamps
    end
  end
end
