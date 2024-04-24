class AddWebauthnFieldsToTwoFactorTable < ActiveRecord::Migration[7.0]
  def change
    add_column :two_factor_authentication_devices, :webauthn_external_id, :string, null: true
    add_index  :two_factor_authentication_devices, :webauthn_external_id, unique: true

    add_column :two_factor_authentication_devices, :webauthn_public_key, :string, null: true
    add_column :two_factor_authentication_devices, :webauthn_sign_count, :bigint, null: false, default: 0

    add_column :users, :webauthn_id, :string, null: true
  end
end
