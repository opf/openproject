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

##
# Intended to be used by the AccountController to implement the user consent
# check.
module Accounts::UserConsent
  extend ActiveSupport::Concern

  include ::UserConsentHelper

  included do
    before_action :require_consenting_user,
                  only: %i[consent confirm_consent]
  end

  def consent
    if user_consent_required? && consenting_user.consent_expired?
      render "account/consent"
    else
      consent_finished
    end
  end

  def confirm_consent
    if consent_param?
      approve_consent!(consenting_user)
    else
      reject_consent!
    end
  end

  def decline_consent
    message = I18n.t("consent.decline_warning_message") + "\n"
    message <<
      if Setting.consent_decline_mail.present?
        I18n.t("consent.contact_this_mail_address", mail_address: Setting.consent_decline_mail)
      else
        I18n.t("consent.contact_your_administrator")
      end

    flash[:error] = message
    redirect_to authentication_stage_failure_path :consent
  end

  private

  def require_consenting_user
    reject_consent! unless consenting_user
  end

  def consenting_user
    @consenting_user ||= User.find_by id: session[:authenticated_user_id]
  end

  def approve_consent!(user)
    user.update_column(:consented_at, DateTime.now)
    consent_finished
  end

  def consent_finished
    redirect_to authentication_stage_complete_path(:consent)
  end

  def reject_consent!
    flash[:error] = I18n.t("consent.failure_message")
    redirect_to authentication_stage_failure_path :consent
  end
end
