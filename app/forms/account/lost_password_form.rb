# frozen_string_literal: true

class Account::LostPasswordForm < ApplicationForm
  form do |form|
    form.text_field(
      name: :mail,
      label: User.human_attribute_name(:mail),
      required: true,
      input_width: :large
    )
    form.submit(name: :submit, label: I18n.t(:button_submit), scheme: :primary)
  end
end
