class AddRecaptchaEntries < ActiveRecord::Migration[5.2]
  def change
    create_table :recaptcha_entries, id: :integer do |t|
      t.references :user, index: true, foreign_key: { on_delete: :cascade }
      t.timestamps
      t.integer :version, null: false
    end
  end
end
