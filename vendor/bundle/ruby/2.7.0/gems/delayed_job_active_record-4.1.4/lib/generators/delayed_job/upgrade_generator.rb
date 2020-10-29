# frozen_string_literal: true

require "generators/delayed_job/delayed_job_generator"
require "generators/delayed_job/next_migration_version"
require "rails/generators/migration"
require "rails/generators/active_record"

# Extend the DelayedJobGenerator so that it creates an AR migration
module DelayedJob
  class UpgradeGenerator < ActiveRecordGenerator
    def create_migration_file
      migration_template(
        "upgrade_migration.rb",
        "db/migrate/add_queue_to_delayed_jobs.rb",
        migration_version: migration_version
      )
    end
  end
end
