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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module OpenProject
  module Recaptcha
    module Configuration
      CONFIG_KEY = "recaptcha_via_hcaptcha".freeze

      extend self

      def enabled?
        type.present? && type != ::OpenProject::Recaptcha::TYPE_DISABLED
      end

      def use_hcaptcha?
        type == ::OpenProject::Recaptcha::TYPE_HCAPTCHA
      end

      def use_turnstile?
        type == ::OpenProject::Recaptcha::TYPE_TURNSTILE
      end

      def use_recaptcha?
        type == ::OpenProject::Recaptcha::TYPE_V2 || type == ::OpenProject::Recaptcha::TYPE_V3
      end

      def type
        ::Setting.plugin_openproject_recaptcha["recaptcha_type"]
      end

      def hcaptcha_response_limit
        (::Setting.plugin_openproject_recaptcha["response_limit"] || "5000").to_i
      end

      def hcaptcha_verify_url
        "https://hcaptcha.com/siteverify"
      end

      def hcaptcha_api_server_url
        "https://hcaptcha.com/1/api.js"
      end
    end
  end
end
