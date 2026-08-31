# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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

module OpenProject
  ##
  # This module is the container for temporary or permanent feature flags.
  #
  # New feature flags can automatically be added by calling
  #
  #   OpenProject::FeatureDecisions.add :the_name_of_the_flag
  #
  # See config/initializers/feature_decisions.rb.
  #
  # This will set up:
  # * the method `.the_name_of_the_flag_active?` for querying the state
  #   of the flag. By default, it is false.
  # * fetching the overwritten value from
  #   * ENV variable (`OPENPROJECT_FEATURE_THE_NAME_OF_THE_FLAG_ACTIVE = 'true'`)
  #   * configuration.yml file (`the_name_of_the_flag_active: true`)
  #   * from the settings database table (`Setting.feature_the_name_of_the_flag_active = true)
  # * including the flag in the `.active` array in case it is enabled
  # * including the flag in the `.all`
  #
  # The setup should be carried out inside an initializer for the overwriting from ENV or configuration.yml
  # to be picked up.
  #
  # A spec in which such a flag is to be enabled can do so via:
  #
  #   context 'some description', with_flag: { the_name_of_the_flag: true } do
  #     ...
  #   end
  #
  # There is an interface to toggle flags on a running instance at path /admin/settings/experimental.
  #
  module FeatureDecisions
    module_function

    ##
    # Adds a new feature flag to the system, setting up flag-specific methods and settings configurations.
    # By default, the feature flag is inactive in production but active in development. A user can
    # choose to activate it via ENV variable or in the administration.
    # Once a feature is fully developed and tested, it can be set to always be active in production
    # by setting `force_active: true`. Then, the ENV variable and the setting will be ignored.
    # After the release, the feature flag can then be removed from the codebase.
    #
    # === Example:
    # Adding a new feature flag:
    #   OpenProject::FeatureDecisions.add :new_ui,
    #                                     description: "Enables the new user interface",
    #                                     force_active: true,
    #                                     allow_enabling: true
    #
    # Querying the state of the feature flag:
    #   OpenProject::FeatureDecisions.new_ui_active? # => true or false based on configuration
    #
    # @param [Symbol] flag_name The name of the feature flag to add.
    # @param [String, nil] description A description of the feature flag for documentation purposes.
    # @param [Boolean] force_active Whether to force the feature flag to be active in production or development environments.
    # @param [Boolean] allow_enabling Whether to allow enabling the feature flag via ENV variable or administration.
    # @return [void]
    ##
    def add(flag_name, description: nil, force_active: false, allow_enabling: true)
      all << flag_name
      define_flag_methods(flag_name)
      define_setting_definition(flag_name, description:,
                                           force_active: force_active && (Rails.env.production? || Rails.env.development?),
                                           allow_enabling: allow_enabling)
    end

    def active
      all.filter { |flag_name| send(:"#{flag_name}_active?") }.map(&:to_s)
    end

    def all
      @all ||= []
    end

    def define_flag_methods(flag_name)
      define_singleton_method :"#{flag_name}_active?" do
        Setting.exists?("feature_#{flag_name}_active") && Setting.send(:"feature_#{flag_name}_active?")
      end
    end

    def define_setting_definition(flag_name, description: nil, force_active: false, allow_enabling: true)
      writable = if force_active
                   false
                 else
                   allow_enabling
                 end

      Settings::Definition.add :"feature_#{flag_name}_active",
                               description:,
                               default: force_active || Rails.env.development?,
                               writable: writable,
                               disallow_override: force_active || !allow_enabling
    end
  end
end
