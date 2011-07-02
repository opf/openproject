namespace :open_id_authentication do
  namespace :db do
    desc "Creates authentication tables for use with OpenIdAuthentication"
    task :create => :environment do
      generate_migration(["open_id_authentication_tables", "add_open_id_authentication_tables"])
    end

    desc "Upgrade authentication tables from ruby-openid 1.x.x to 2.x.x"
    task :upgrade => :environment do
      generate_migration(["upgrade_open_id_authentication_tables", "upgrade_open_id_authentication_tables"])
    end

    def generate_migration(args)
      require 'rails_generator'
      require 'rails_generator/scripts/generate'

      if ActiveRecord::Base.connection.supports_migrations?
        Rails::Generator::Scripts::Generate.new.run(args)
      else
        raise "Task unavailable to this database (no migration support)"
      end
    end

    desc "Clear the authentication tables"
    task :clear => :environment do
      OpenIdAuthentication::DbStore.cleanup_nonces
      OpenIdAuthentication::DbStore.cleanup_associations
    end
  end
end
