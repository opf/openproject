# frozen_string_literal: true

class TwoFactorAuthentication::Devices::WebauthnDeviceForm < ApplicationForm
  def initialize(index_path:)
    super()
    @index_path = index_path
  end

  form do |f|
    f.fieldset_group(title: model.name,
                     description: helpers.t("two_factor_authentication.devices.webauthn.further_steps")) do |fg|
      fg.text_field(
        name: :identifier,
        label: attribute_name(:identifier),
        required: true,
        caption: helpers.t("two_factor_authentication.devices.text_identifier")
      )
    end

    f.html_content do
      helpers.hidden_field_tag(
        "device[webauthn_credential]",
        "",
        "data-two-factor-authentication-target": "webauthnCredential"
      )
    end

    f.html_content do
      helpers.content_tag(:div, "",
                          class: "form--field-error",
                          data: { "two-factor-authentication-target": "errorDisplay" })
    end

    f.group(layout: :horizontal) do |button_group|
      button_group.button(name: :cancel,
                          tag: :a,
                          label: helpers.t(:button_cancel),
                          scheme: :default,
                          href: @index_path) do |button|
        button.with_leading_visual_icon(icon: :x)
        helpers.t(:button_cancel)
      end
      button_group.submit(name: :submit, label: I18n.t(:button_continue), scheme: :primary) do |button|
        button.with_leading_visual_icon(icon: :check)
        helpers.t(:button_continue)
      end
    end
  end
end
