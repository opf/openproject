class CreateEnterpriseToken < ActiveRecord::Migration[5.1]
  def change
    create_table :enterprise_tokens, id: :integer do |t|
      t.text :encoded_token

      t.timestamps
    end
  end
end
