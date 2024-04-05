class UpdateAccessManagementOfConfiguredOneDriveStorages < ActiveRecord::Migration[7.1]
  def up
    execute <<-SQL.squish
      UPDATE storages
      SET provider_fields = jsonb_set(provider_fields, '{automatically_managed}', 'false', true)
      WHERE provider_type = 'Storages::OneDriveStorage' AND provider_fields->>'automatically_managed' is null;
    SQL
  end

  def down; end
end
