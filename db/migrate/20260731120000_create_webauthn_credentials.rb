# frozen_string_literal: true

class CreateWebauthnCredentials < ActiveRecord::Migration[8.1]
  def change
    create_table :webauthn_credentials do |t|
      t.references :user, null: false, foreign_key: true

      t.string :external_id, null: false
      t.text :public_key, null: false
      t.bigint :sign_count, null: false, default: 0
      t.string :name
      t.datetime :last_used_at

      t.timestamps

      t.index :external_id, unique: true, name: "index_webauthn_credentials_on_external_id"
    end
  end
end
