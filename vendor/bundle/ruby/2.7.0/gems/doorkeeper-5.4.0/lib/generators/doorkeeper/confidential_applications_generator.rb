# frozen_string_literal: true

require "rails/generators"
require "rails/generators/active_record"

module Doorkeeper
  # Generates migration to add confidential column to Doorkeeper
  # applications table.
  #
  class ConfidentialApplicationsGenerator < ::Rails::Generators::Base
    include ::Rails::Generators::Migration
    source_root File.expand_path("templates", __dir__)
    desc "Add confidential column to Doorkeeper applications"

    def confidential_applications
      migration_template(
        "add_confidential_to_applications.rb.erb",
        "db/migrate/add_confidential_to_applications.rb",
        migration_version: migration_version,
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
