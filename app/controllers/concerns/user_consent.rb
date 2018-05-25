#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See doc/COPYRIGHT.rdoc for more details.
#++

##
# Intended to be used by the AccountController to implement the user consent
# check.
module Concerns::UserConsent
  def consent
    if consent_required?
      render 'account/consent', locals: { consent_info: consent_info }
    else
      consent_finished
    end
  end

  def confirm_consent
    user = consenting_user

    if user.present? && params[:consent_check]
      approve_consent!(user)
    else
      reject_consent!
    end
  end

  def decline_consent
    message = I18n.t('consent.decline_warning_message') + "\n"
    message <<
      if Setting.consent_decline_mail
        I18n.t('consent.contact_this_mail_address', mail_address: Setting.consent_decline_mail)
      else
        I18n.t('consent.contact_your_administrator')
      end

    flash[:error] = message
    redirect_to authentication_stage_failure_path :consent
  end

  def consent_required?
    # Ensure consent is enabled
    return false unless Setting.consent_required?

    # Ensure at least one translation is provided
    if Setting.consent_info.count == 0
      Rails.logger.error 'Instance is configured to require consent, but no consent_info has been set.'
      return false
    end

    # Require the user to consent if he hasn't already
    consenting_user.consented_at.nil?
  end

  def consent_info
    all = Setting.consent_info
    all.fetch(I18n.locale) { all.values.first }
  end

  def consenting_user
    User.find_by id: session[:authenticated_user_id]
  end

  def approve_consent!(user)
    user.update_column(:consented_at, DateTime.now)
    consent_finished
  end

  def consent_finished
    redirect_to authentication_stage_complete_path(:consent)
  end

  def reject_consent!
    flash[:error] = I18n.t('consent.failure_message')
    redirect_to authentication_stage_failure_path :consent
  end
end
