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

  form do |f|
    login_or_email(f) if model.ldap_auth_source_id.nil?

    f.text_field(name: :firstname, label: attribute_name(:firstname), required: true, input_width:)
    f.text_field(name: :lastname, label: attribute_name(:lastname), required: true, input_width:)

    if show_email?
      f.text_field(name: :mail,
                   type: :email,
                   label: attribute_name(:mail),
                   required: true,
                   readonly: !registration_mail_editable?,
                   input_width:)
    end

    f.html_content { helpers.call_hook(:view_account_register_after_basic_information, f:) }

    render_custom_fields(form: f)

    password_fields(f) if model.change_password_allowed?

    consent(f) if helpers.user_consent_required?

    f.submit(name: :submit, label: I18n.t(:button_create), scheme: :primary)

    authentication_providers(f) unless model.uses_external_authentication?
    registration_footer(f)
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
      helpers.content_tag(:div, class: "op-consent-instructions") do
        helpers.format_text(helpers.user_consent_instructions(I18n.locale), target: "_blank")
      end
    end
    form.check_box(name: :consent_check,
                   id: "user_consent_check",
                   label: helpers.format_text(helpers.consent_checkbox_label),
                   required: true)
    consent_validation_message(form)
  end

  # Primer's check_box does not render inline validations, so we render the
  # consent error next to the checkbox ourselves, matching the styling Primer
  # uses for other inline field validations.
  def consent_validation_message(form)
    message = model.errors[:consent_check].first
    return if message.blank?

    form.html_content do
      helpers.content_tag(:div, class: "FormControl-inlineValidation") do
        helpers.safe_join([
                            helpers.content_tag(
                              :span,
                              render(Primer::Beta::Octicon.new(icon: :"alert-fill", size: :xsmall, aria: { hidden: true })),
                              class: "FormControl-inlineValidation--visual"
                            ),
                            helpers.content_tag(:span, message)
                          ])
      end
    end
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
