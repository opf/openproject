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

module EnterpriseTrials
  class AugurCreateTrialService < BaseServices::BaseCallable
    attr_reader :trial

    def initialize(trial)
      @trial = trial
      super()
    end

    def perform
      handle_response(
        OpenProject.httpx.post(
          URI.join(augur_host, "/public/v1/trials"),
          json: trial.to_h.merge(
            version: OpenProject::VERSION.to_semver,
            token_version: OpenProject::Token::VERSION,
            domain: Setting.host_name
          )
        )
      )
    end

    private

    def handle_response(response)
      case response
      in { status: 202 }
        handle_successful_trial(response.json)
      in { status: 422 }
        handle_conflicts(response)
      else
        handle_error(response)
      end
    end

    def handle_successful_trial(trial_json)
      value = trial_json["id"]

      if value.blank?
        trial.errors.add(:base, :failed_to_create, status: "Missing trial ID")
        return ServiceResult.failure(result: trial)
      end

      data = { email: trial.email }
      trial_key = Token::EnterpriseTrialKey.create!(user_id: User.system.id, value:, data:)
      ServiceResult.success(result: trial_key)
    end

    def handle_error(error_response)
      error = safe_response_json(error_response)

      if error.is_a?(Hash) && error["description"]
        trial.errors.add(:base, error["description"])
      else
        status = error_response&.status || "internal error"
        trial.errors.add(:base, :failed_to_create, status: "HTTP response failed: #{status}")
      end

      ServiceResult.failure(result: trial)
    end

    def handle_conflicts(response)
      error = safe_response_json(response)

      case error["identifier"]
      when "user_already_created_trial"
        trial.errors.add(:email, :already_used)
      when "domain_taken"
        trial.errors.add(:domain, :already_used)
      when "invalid_email"
        trial.errors.add(:email, :invalid)
      else
        handle_error(response)
      end

      ServiceResult.failure(result: trial)
    end

    def safe_response_json(response)
      response.json
    rescue HTTPX::Error
      {}
    end

    def augur_host
      OpenProject::Configuration.enterprise_trial_creation_host
    end
  end
end
