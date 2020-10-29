# frozen_string_literal: true

require "rails/generators"
require "rails/generators/active_record"

module Doorkeeper
  # Generates migration with polymorphic resource owner required
  # database columns for Doorkeeper Access Token and Access Grant
  # models.
  #
  class EnablePolymorphicResourceOwnerGenerator < ::Rails::Generators::Base
    include ::Rails::Generators::Migration
    source_root File.expand_path("templates", __dir__)
    desc "Provide support for polymorphic Resource Owner."

    def enable_polymorphic_resource_owner
      migration_template(
        "enable_polymorphic_resource_owner_migration.rb.erb",
        "db/migrate/enable_polymorphic_resource_owner.rb",
        migration_version: migration_version,
      )
      gsub_file(
        "config/initializers/doorkeeper.rb",
        "# use_polymorphic_resource_owner",
        "use_polymorphic_resource_owner",
      )
    end

    def self.next_migration_number(dirname)
      ActiveRecord::Generators::Base.next_migration_number(dirname)
    end

    private

    def migration_version
      "[#{ActiveRecord::VERSION::MAJOR}.#{ActiveRecord::VERSION::MINOR}]"
    end
  end
end
