# frozen_string_literal: true

class CreateBimApiTokens < ActiveRecord::Migration[8.0]
  def change
    create_table :bim_api_tokens do |t|
      t.references :user,
                   null: false,
                   foreign_key: { to_table: :users, on_delete: :cascade },
                   index: true
      t.references :project,
                   foreign_key: { to_table: :projects, on_delete: :cascade },
                   index: true

      t.string :name, null: false, limit: 255
      t.text :description

      # Token hash (never store plain token)
      t.string :token_hash, null: false, limit: 128

      # Token prefix for identification (first 8 chars of token)
      t.string :token_prefix, null: false, limit: 16

      # Scopes: what this token can access
      # e.g., ['read:models', 'write:models', 'run:clashes']
      t.jsonb :scopes, default: [], null: false

      # Token status
      t.boolean :active, default: true, null: false

      # Expiration
      t.datetime :expires_at
      t.datetime :last_used_at

      # Usage tracking
      t.integer :usage_count, default: 0, null: false
      t.inet :last_used_ip

      t.timestamps null: false
    end

    # Unique index on token_hash for fast lookups
    add_index :bim_api_tokens, :token_hash, unique: true, name: 'idx_unique_token_hash'

    # Index on token_prefix for token identification
    add_index :bim_api_tokens, :token_prefix, name: 'idx_api_tokens_prefix'

    # Index on active status
    add_index :bim_api_tokens, :active, name: 'idx_api_tokens_active'

    # Index on expires_at for cleanup jobs
    add_index :bim_api_tokens, :expires_at, name: 'idx_api_tokens_expires'

    # GIN index for scopes JSONB
    reversible do |dir|
      dir.up do
        execute <<-SQL
          CREATE INDEX idx_api_tokens_scopes ON bim_api_tokens USING GIN (scopes);
        SQL
      end

      dir.down do
        execute <<-SQL
          DROP INDEX IF EXISTS idx_api_tokens_scopes;
        SQL
      end
    end
  end
end
