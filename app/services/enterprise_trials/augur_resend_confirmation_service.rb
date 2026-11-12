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
  class AugurResendConfirmationService
    def initialize(trial_key)
      @trial_key = trial_key
    end

    def call
      handle_response(
        OpenProject.httpx.post(
          URI.join(augur_host, "/public/v1/trials/#{@trial_key.value}/resend")
        )
      )
    end

    private

    def handle_response(response)
      case response
      in { status: 200 | 202 }
        ServiceResult.success(result: nil)
      in { status: 404 }
        ServiceResult.failure(message: I18n.t("ee.trial.not_found"))
      else
        Rails.logger.error { "Unexpected response from Augur: #{response.inspect}" }
        ServiceResult.failure(message: I18n.t("js.error.internal"))
      end
    end

    def augur_host
      OpenProject::Configuration.enterprise_trial_creation_host
    end
  end
end
