require 'rails/generators'
require "rails/generators/active_record"

# This generator adds a migration for the {FriendlyId::History
# FriendlyId::History} addon.
class FriendlyIdGenerator < ActiveRecord::Generators::Base
  # ActiveRecord::Generators::Base inherits from Rails::Generators::NamedBase which requires a NAME parameter for the
  # new table name. Our generator always uses 'friendly_id_slugs', so we just set a random name here.
  argument :name, type: :string, default: 'random_name'

  class_option :'skip-migration', :type => :boolean, :desc => "Don't generate a migration for the slugs table"
  class_option :'skip-initializer', :type => :boolean, :desc => "Don't generate an initializer"

  source_root File.expand_path('../../friendly_id', __FILE__)

  # Copies the migration template to db/migrate.
  def copy_files
    return if options['skip-migration']
    migration_template 'migration.rb', 'db/migrate/create_friendly_id_slugs.rb'
  end

  def create_initializer
    return if options['skip-initializer']
    copy_file 'initializer.rb', 'config/initializers/friendly_id.rb'
  end
end
