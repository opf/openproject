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
class EnterpriseTrialsController < ApplicationController
  include OpTurbo::ComponentStream

  before_action :require_admin
  before_action :load_trial_key, only: %i[request_resend]

  def trial_dialog
    respond_with_dialog EnterpriseTrials::DialogComponent.new(EnterpriseTrial.new)
  end

  def request_resend
    EnterpriseTrials::AugurResendConfirmationService
      .new(@trial_key)
      .call

    redirect_to enterprise_tokens_path, status: :see_other
  end

  def create
    call = EnterpriseTrials::CreateService
      .new(user: current_user)
      .call(trial_params.to_h)

    if call.success?
      redirect_to enterprise_tokens_path, status: :see_other
    else
      form_component = EnterpriseTrials::FormComponent.new(call.result)
      update_via_turbo_stream(component: form_component, status: :bad_request)
      respond_with_turbo_streams
    end
  end

  private

  def load_trial_key
    @trial_key = Token::EnterpriseTrialKey.find_by!(user_id: User.system.id)
  end

  def trial_params
    params
      .expect(enterprise_trial: %i[company firstname lastname email general_consent newsletter_consent])
  end
end
