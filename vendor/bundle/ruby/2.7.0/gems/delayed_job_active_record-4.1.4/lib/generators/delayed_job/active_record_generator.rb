# frozen_string_literal: true

require "generators/delayed_job/delayed_job_generator"
require "generators/delayed_job/next_migration_version"
require "rails/generators/migration"
require "rails/generators/active_record"

# Extend the DelayedJobGenerator so that it creates an AR migration
module DelayedJob
  class ActiveRecordGenerator < ::DelayedJobGenerator
    include Rails::Generators::Migration
    extend NextMigrationVersion

    source_paths << File.join(File.dirname(__FILE__), "templates")

    def create_migration_file
      migration_template "migration.rb", "db/migrate/create_delayed_jobs.rb", migration_version: migration_version
    end

    def self.next_migration_number(dirname)
      ActiveRecord::Generators::Base.next_migration_number dirname
    end

    private

    def migration_version
      "[#{ActiveRecord::VERSION::MAJOR}.#{ActiveRecord::VERSION::MINOR}]" if ActiveRecord::VERSION::MAJOR >= 5
    end
  end
end
