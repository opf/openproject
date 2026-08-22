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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Llm
  module Validators
    # What can be said about the connection without asking the server anything.
    class ConfigurationValidator < HealthReports::ValidatorGroup
      def self.key = :configuration

      private

      def validate
        register_checks(:feature_flag, :base_url_present, :api_format_supported, :credentials_present, :enabled)

        feature_flag
        base_url_present
        api_format_supported
        credentials_present
        connection_enabled
      end

      def feature_flag
        if OpenProject::FeatureDecisions.llm_connection_active?
          pass_check(:feature_flag)
        else
          # Not a failure: an administrator may reasonably configure and test the
          # connection before switching the feature on.
          warn_check(:feature_flag, :feature_flag_off)
        end
      end

      def base_url_present
        return pass_check(:base_url_present) if subject.base_url.present?

        fail_check(:base_url_present, :not_configured)
      end

      def api_format_supported
        return pass_check(:api_format_supported) if Llm::Session.supports?(subject.api_format)

        fail_check(:api_format_supported, :unsupported_api_format, context: { api_format: subject.api_format.to_s })
      end

      # Only ever a warning. A self-hosted server on a trusted network legitimately
      # needs no credential, and a key that is genuinely required but wrong is
      # reported precisely by the server group rather than guessed at here.
      def credentials_present
        return pass_check(:credentials_present) if subject.api_key.present?

        warn_check(:credentials_present, :api_key_missing)
      end

      def connection_enabled
        return pass_check(:enabled) if subject.enabled?

        warn_check(:enabled, :connection_disabled)
      end
    end
  end
end
