class RemovePlaintextTokens < ActiveRecord::Migration[7.0]
  def change
    drop_table :plaintext_tokens do |t|
      t.integer :user_id, default: 0, null: false
      t.string :action, limit: 30, default: '', null: false
      t.string :value, limit: 40, default: '', null: false
      t.datetime :created_on, null: false

      t.index :user_id, name: 'index_plaintext_tokens_on_user_id'
    end
  end
end
