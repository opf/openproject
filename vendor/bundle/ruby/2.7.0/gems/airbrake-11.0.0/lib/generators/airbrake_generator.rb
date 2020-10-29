# frozen_string_literal: true

# Creates the Airbrake initializer file for Rails apps.
#
# @example Invokation from terminal
#   rails generate airbrake PROJECT_KEY PROJECT_ID [NAME]
#
class AirbrakeGenerator < Rails::Generators::Base
  # Adds current directory to source paths, so we can find the template file.
  source_root File.expand_path(__dir__)

  argument :project_id, required: false
  argument :project_key, required: false

  # Makes the NAME option optional, which allows to subclass from Base, so we
  # can pass arguments to the ERB template.
  #
  # @see http://asciicasts.com/episodes/218-making-generators-in-rails-3
  argument :name, type: :string, default: 'application'

  desc 'Configures the Airbrake notifier with your project id and project key'
  def generate_layout
    template 'airbrake_initializer.rb.erb', 'config/initializers/airbrake.rb'
  end
end
