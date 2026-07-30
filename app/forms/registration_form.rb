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

class RegistrationForm < ApplicationForm
  include CustomFields::CustomFieldRendering

  form do |form|
    login_or_email(form) if model.ldap_auth_source_id.nil?

    form.text_field(name: :firstname, label: attribute_name(:firstname), required: true, input_width:)
    form.text_field(name: :lastname, label: attribute_name(:lastname), required: true, input_width:)

    if show_email?
      form.text_field(name: :mail,
                      type: :email,
                      label: attribute_name(:mail),
                      required: true,
                      readonly: !registration_mail_editable?,
                      input_width:)
    end

    form.html_content { helpers.call_hook(:view_account_register_after_basic_information, f: form) }

    render_custom_fields(form:)

    password_fields(form) if model.change_password_allowed?

    consent(form) if helpers.user_consent_required?

    form.submit(name: :submit, label: I18n.t(:button_create), scheme: :primary)

    authentication_providers(form)
    registration_footer(form)
  end

  private

  def login_or_email(form)
    if Setting.email_login?
      form.text_field(name: :mail,
                      type: :email,
                      label: attribute_name(:mail),
                      required: true,
                      readonly: !registration_mail_editable?,
                      input_width:)
    else
      form.text_field(name: :login, label: attribute_name(:login), required: true, input_width:)
    end
  end

  def show_email?
    !Setting.email_login? || model.ldap_auth_source_id.present?
  end

  def registration_mail_editable?
    Setting.user_can_change_email? || model.new_record?
  end

  def password_fields(form)
    form.group(data: { controller: "password-requirements" }) do |group|
      group.text_field(name: :password,
                       id: "user_password",
                       type: :password,
                       label: attribute_name(:password),
                       required: true,
                       autocomplete: "new-password",
                       caption: helpers.password_complexity_requirements,
                       input_width:,
                       data: { "password-requirements-target": "passwordInput" })
      group.text_field(name: :password_confirmation,
                       id: "user_password_confirmation",
                       type: :password,
                       label: attribute_name(:password_confirmation),
                       required: true,
                       autocomplete: "new-password",
                       input_width:)
    end
  end

  def consent(form)
    form.html_content do
      helpers.format_text(helpers.user_consent_instructions(I18n.locale), target: "_blank")
    end
    form.check_box(name: :consent_check,
                   scope_name_to_model: false,
                   label: helpers.format_text(helpers.consent_checkbox_label),
                   required: true)
  end

  def authentication_providers(form)
    form.html_content do
      render("account/auth_providers", omniauth_title: I18n.t("account.signup_with_external_account"), wide: true)
    end
  end

  def registration_footer(form)
    return unless (footer = helpers.registration_footer)

    form.html_content { render(Primer::Beta::Text.new(tag: :div, mt: 3)) { footer } }
  end

  def custom_fields
    model.available_custom_fields.select(&:is_required?)
  end

  def additional_custom_field_input_arguments
    { input_width: }
  end

  def input_width
    :large
  end
end
