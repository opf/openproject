#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

# Seeds the minimum data required to run OpenProject (BasicDataSeeder, AdminUserSeeder)
# as well as optional demo data (DemoDataSeeder) to give a user some orientation.
class RootSeeder < Seeder
  attr_reader :raise_on_unknown_language

  def initialize(seed_development_data: Rails.env.development?, raise_on_unknown_language: false)
    super()

    @seed_development_data = seed_development_data
    @raise_on_unknown_language = raise_on_unknown_language

    load_available_seeders
  end

  # Returns the demo data in the default language.
  def seed_data
    @seed_data ||= begin
      raise 'cannot generate demo seed data without setting locale first' unless @locale_set

      Source::SeedDataLoader.get_data
    end
  end

  def translated_seed_data_for(*keys)
    set_locale! do
      Source::SeedDataLoader.get_data(only: keys)
    end
  end

  def seed_data!
    reset_active_record!
    set_locale! do
      print_status "*** Seeding for locale: '#{I18n.locale}'"
      prepare_seed! do
        ActiveRecord::Base.transaction do
          block_given? ? (yield self) : do_seed!
        end
      end
    end
  end

  def do_seed!
    # Basic data needs be seeded before anything else.
    seed_basic_data
    seed_admin_user
    seed_demo_data
    seed_development_data if seed_development_data?
    seed_plugins_data
    seed_env_data
  end

  def seed_development_data?
    @seed_development_data
  end

  private

  # Load all seeders so that they can be discovered when doing
  # `Seeder.subclasses`.
  def load_available_seeders
    load_engine_seeders(Rails)
    rails_engines.each { |engine| load_engine_seeders engine }
  end

  def load_engine_seeders(engine)
    engine.root.glob('app/seeders/**/*.rb')
      .each { |file| require file }
  end

  def rails_engines
    ::Rails::Engine.subclasses.map(&:instance)
  end

  ##
  # Clears some schema caches and column information.
  def reset_active_record!
    ActiveRecord::Base
      .descendants
      .reject(&:abstract_class?)
      .each do |klass|
      klass.connection.schema_cache.clear!
      klass.reset_column_information
    end
  end

  def set_locale!
    I18n.with_locale(desired_lang) do
      @locale_set = true
      yield
    end
  ensure
    @locale_set = false
  end

  def prepare_seed!
    # Disable mail delivery for the duration of this task
    previous_perform_deliveries = ActionMailer::Base.perform_deliveries
    ActionMailer::Base.perform_deliveries = false

    # Avoid asynchronous DeliverWorkPackageCreatedJob
    previous_delay_jobs = Delayed::Worker.delay_jobs
    Delayed::Worker.delay_jobs = false

    yield
  ensure
    ActionMailer::Base.perform_deliveries = previous_perform_deliveries
    Delayed::Worker.delay_jobs = previous_delay_jobs
  end

  def seed_basic_data
    print_status "*** Seeding basic data for #{OpenProject::Configuration['edition']} edition"
    ::Standard::BasicDataSeeder.new(seed_data).seed!
  end

  def seed_admin_user
    print_status '*** Seeding admin user'
    AdminUserSeeder.new(seed_data).seed!
  end

  def seed_demo_data
    print_status '*** Seeding demo data'
    DemoDataSeeder.new(seed_data).seed!
  end

  def seed_env_data
    print_status '*** Seeding data from environment variables'
    EnvDataSeeder.new(seed_data).seed!
  end

  def seed_development_data
    print_status '*** Seeding development data'
    require 'factory_bot'
    # Load FactoryBot factories
    begin
      ::FactoryBot.find_definitions
    rescue StandardError => e
      raise e unless e.message.downcase.include? "factory already registered"
    end

    DevelopmentDataSeeder.new(seed_data).seed!
  end

  def seed_plugins_data
    rails_engines.each do |engine|
      print_status "*** Loading #{engine.engine_name} seed data"
      engine.load_seed
    end
  end

  def desired_lang
    desired_lang = ENV.fetch('OPENPROJECT_SEED_LOCALE', Setting.default_language)

    if Redmine::I18n.all_languages.exclude?(desired_lang)
      if raise_on_unknown_language
        raise "Locale #{desired_lang} is not supported"
      else
        desired_lang = :en
      end
    end

    desired_lang
  end
end
