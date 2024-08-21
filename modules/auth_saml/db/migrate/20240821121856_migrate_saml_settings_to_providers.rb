class MigrateSamlSettingsToProviders < ActiveRecord::Migration[7.1]
  def up
    providers = Hash(Setting.plugin_openproject_auth_saml).with_indifferent_access[:providers]
    return if providers.blank?

    providers.each do |name, options|
      migrate_provider!(name, options)
    end
  end

  def down
    # This migration does not yet remove Setting.plugin_openproject_auth_saml
    # so it can be retried.
  end

  private

  def migrate_provider!(name, options)
    puts "Trying to migrate SAML provider #{name} from previous settings format..."
    call = ::Saml::SyncService.new(name, options).call

    if call.success
      puts <<~SUCCESS
        Successfully migrated SAML provider #{name} from previous settings format.
        You can now manage this provider in the new administrative UI within OpenProject under
        the "Administration -> Authentication -> SAML providers" section.
      SUCCESS
    else
      raise <<~ERROR
        Failed to create or update SAML provider #{name} from previous settings format.
        The error message was: #{call.message}

        Please check the logs for more information and open a bug report in our community:
        https://www.openproject.org/docs/development/report-a-bug/

        If you would like to skip migrating the SAML setting and discard them instead, you can use our documentation
        to unset any previous SAML settings:

        https://www.openproject.org/docs/system-admin-guide/authentication/saml/
      ERROR
    end
  end
end
