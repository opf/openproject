class MoveHashedTokenToCore < ActiveRecord::Migration[5.1]
  class OldToken < ActiveRecord::Base
    self.table_name = :plaintext_tokens
  end

  def up
    rename_table :tokens, :plaintext_tokens
    create_tokens_table
    migrate_existing_tokens
  end

  def down
    drop_table :tokens
    rename_table :plaintext_tokens, :tokens
  end

  private

  def create_tokens_table
    create_table :tokens, id: :integer do |t|
      t.references :user, index: true
      t.string :type
      t.string :value, default: "", null: false, limit: 128
      t.datetime :created_on, null: false
      t.datetime :expires_on, null: true
    end
  end

  def migrate_existing_tokens
    # API tokens
    ::Token::API.transaction do
      OldToken.where(action: 'api').find_each do |token|
        result = ::Token::API.create(user_id: token.user_id, value: ::Token::API.hash_function(token.value))
        warn "Failed to migrate API token for ##{user.id}" unless result
      end
    end

    # RSS tokens
    ::Token::RSS.transaction do
      OldToken.where(action: 'feeds').find_each do |token|
        result = ::Token::RSS.create(user_id: token.user_id, value: token.value)
        warn "Failed to migrate RSS token for ##{user.id}" unless result
      end
    end

    # We do not migrate the rest, they are short-lived anyway.
  end
end
