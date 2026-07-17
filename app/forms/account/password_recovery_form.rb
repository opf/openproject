# frozen_string_literal: true

class Account::PasswordRecoveryForm < ApplicationForm
  form do |form|
    form.group(data: { controller: "password-requirements" }) do |group|
      group.text_field(
        name: :new_password,
        label: User.human_attribute_name(:new_password),
        type: :password,
        required: true,
        autocomplete: "off",
        caption: helpers.password_complexity_requirements,
        input_width: :large,
        data: { "password-requirements-target": "passwordInput" }
      )
      group.text_field(
        name: :new_password_confirmation,
        label: User.human_attribute_name(:password_confirmation),
        type: :password,
        required: true,
        autocomplete: "off",
        input_width: :large
      )
    end
    form.submit(name: :submit, label: I18n.t(:button_save), scheme: :primary)
  end
end
