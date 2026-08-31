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

module Users
  # Coordinates the administration user form: receives the surrounding
  # `settings_primer_form_with` builder, composes the inner forms into a
  # Primer::Forms::FormList and renders the read-only / plain bits (status,
  # consent, external auth, hooks, submit) and the pref-scoped preferences form
  # around it. Create vs edit is derived from `user.new_record?`.
  class FormComponent < ApplicationComponent
    def initialize(builder:, user:, contract:)
      super()
      @builder = builder
      @user = user
      @contract = contract
    end

    private

    def creating? = @user.new_record?
    def editing? = !creating?

    def form_list
      Primer::Forms::FormList.new(*input_forms)
    end

    def input_forms
      forms = [Users::Form::AttributesForm.new(@builder, user: @user, contract: @contract)]
      if show_authentication?
        forms << Users::Form::AuthenticationForm.new(@builder,
                                                     user: @user,
                                                     render_auth_source: show_auth_source?,
                                                     render_password: show_password?,
                                                     render_no_login_message: show_no_login_message?,
                                                     render_external_auth: show_external_auth?,
                                                     assign_random_password_checked: assign_random_password_checked?)
      end
      forms << Users::Form::ConsentForm.new(@builder, user: @user) if show_consent?
      forms
    end

    def show_authentication?
      show_auth_source? || show_password? || show_no_login_message? || show_external_auth?
    end

    def show_auth_source?
      return false if editing? && @user.uses_external_authentication?

      creating? ? can_users_have_auth_source? : (User.current.admin? || can_users_have_auth_source?)
    end

    def show_password?
      editing? && User.current.admin? && !@user.uses_external_authentication? && !disable_password_login?
    end

    def show_preferences? = editing? && User.current.admin?
    def show_external_auth? = editing? && @user.uses_external_authentication?

    def show_no_login_message?
      editing? && User.current.admin? && !@user.uses_external_authentication? && disable_password_login?
    end

    def show_consent? = editing? && Setting.consent_required?

    def can_users_have_auth_source?
      LdapAuthSource.any? && !disable_password_login?
    end

    def disable_password_login?
      OpenProject::Configuration.disable_password_login?
    end

    def assign_random_password_checked?
      helpers.params.dig(:user, :assign_random_password).present?
    end
  end
end
