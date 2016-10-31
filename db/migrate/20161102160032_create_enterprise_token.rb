class CreateEnterpriseToken < ActiveRecord::Migration[5.0]
  def change
    create_table :enterprise_tokens do |t|
      t.text :encoded_token

      t.timestamps
    end
  end
end
