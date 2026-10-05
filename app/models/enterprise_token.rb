############ If you are using DOCKER all-in-one image, create Dockerfile like:         ################
############ FROM openproject/openproject:16                                           ################
############ COPY ./enterprise_token.rb app/models/enterprise_token.rb                 ################

############ If you are runing a manual installation:                                  ################
############ REPLACE app/models/enterprise_token.rb in the source code with this file! ################
############ also be sure to RESTART OpenProject after replacing the file.             ################

############ If using some other set up (eg docker-compose), read the comments on      ################
############ https://gist.github.com/markasoftware/f5b2e55a2c2e3abb1f9eefcdf0bfff45    ################

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
class EnterpriseToken < ApplicationRecord
  class << self
    # On the backend, features are checked only using `allows_to?`, which we can hardcode to return `true`.
    # On the frontend, however, it instead checks if particular strings are included in the `available_features`
    # Unfortunately there is no canonical variable with all the features, so we have to hardcode.
    # Use `rg --pcre2 -INo "(?<=allows_to\?[^:*]:|allowsTo\(')[a-z_]*" | sort -u` to generate this list:
    TRUE_FEATURES = %i[
      # these have been removed from openproject but we keep them for older version compaibility:
      board_view
      conditional_highlighting
      # these are in latest openproject:
      allowed_action
      baseline_comparison
      calculated_values
      capture_external_links
      custom_actions
      custom_field_hierarchies
      customize_life_cycle
      date_alerts
      define_custom_style
      edit_attribute_groups
      forbidden_action
      gantt_pdf_export
      internal_comments
      ldap_groups
      mcp_server
      meeting_templates
      multiple_active_sprints
      nextcloud_sso
      one_drive_sharepoint_file_storage
      placeholder_users
      portfolio_management
      project_creation_wizard
      readonly_work_packages
      resource_management
      scim_api
      sprint_sharing
      sso_auth_providers
      team_planner_view
      time_entry_time_restrictions
      virus_scanning
      work_package_query_relation_columns
      work_package_sharing
      work_package_subject_generation
      xwiki_integration
    ].freeze

    # Not all the methods here are ever actually called outside the enterprise_token.rb file itself
    # in upstream openproject, but I'll include all of them that can be reasonably implemented here,
    # just in case openproject changes in the future to start using the extra methods.
    def current
      self.new
    end

    def all_tokens
      [self.new]
    end

    def active_tokens
      [self.new]
    end

    def active_non_trial_tokens
      [self.new]
    end

    def active_trial_tokens
      []
    end

    def active_trial_token
      nil
    end

    def allows_to?(feature)
      true
    end

    def active?
      true
    end

    def trial_only?
      false
    end

    def available_features
      TRUE_FEATURES
    end

    def non_trialling_features
      TRUE_FEATURES
    end

    def trialling_features
      []
    end

    def trialling?(feature)
      false
    end

    def hide_banners?
      true
    end

    def show_banners?
      false
    end

    def user_limit
      nil
    end

    def non_trial_user_limit
      nil
    end

    def trial_user_limit
      nil
    end

    def banner_type_for(feature:)
      nil
    end

    def get_user_limit_of(tokens)
      nil
    end
  end

  FAR_FUTURE_DATE = Date.new(9999, 1, 1)

  def token_object
    Class.new do
      def id
        "lmao"
      end

      def has_feature?(feature)
        true
      end

      def will_expire?
        false
      end

      def mail
        "admin@example.com"
      end

      def subscriber
        "ETC-JSC"
      end

      def company
        "ETC Join Stock Company"
      end

      def domain
        "op.etc.vn"
      end

      def issued_at
        Time.zone.today
      end
      
      def starts_at
        Time.zone.today.beginning_of_year
      end
      
      def expires_at
        Time.zone.today.end_of_year
      end

      def reprieve_days
        nil
      end

      def reprieve_days_left
        69
      end

      def restrictions
        nil
      end

      def available_features
        EnterpriseToken.TRUE_FEATURES
      end

      def plan
        "enterprise"
      end

      def features
        EnterpriseToken.TRUE_FEATURES
      end
      
      def version
        69
      end

      def started?
        true
      end

      def trial?
        false
      end

      def active?
        true
      end
    end.new
  end

  def id
    "lmao"
  end

  def encoded_token
    "oaml"
  end

  def will_expire?
    false
  end

  def mail
    "admin@example.com"
  end

  def subscriber
    "enterprise-mode"
  end

  def company
    "ETC JSC"
  end

  def domain
    "op.etc.vn"
  end

  def issued_at
    Time.zone.today - 1
  end

  def starts_at
    Time.zone.today - 1
  end

  def expires_at
    Time.zone.today + 1
  end

  def reprieve_days
    nil
  end

  def reprieve_days_left
    69
  end

  def restrictions
    nil
  end

  def available_features
    EnterpriseToken.TRUE_FEATURES
  end

  def plan
    "enterprise_mode"
  end

  def features
    EnterpriseToken.TRUE_FEATURES
  end
  
  def version
    69
  end

  def started?
    true
  end

  def trial?
    false
  end

  def active?
    true
  end

  def allows_to?(action)
    true
  end

  def expiring_soon?
    false
  end

  def in_grace_period?
    false
  end

  def expired?(reprieve: true)
    false
  end

  def statuses
    []
  end

  def invalid_domain?
    false
  end

  def unlimited_users?
    true
  end

  def max_active_users
    nil
  end

  def sort_key
    [FAR_FUTURE_DATE, FAR_FUTURE_DATE]
  end

  def days_left
    69
  end
end