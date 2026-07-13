# frozen_string_literal: true

class TwoFactorAuthentication::Devices::TotpDeviceForm < ApplicationForm
  def initialize(index_path:)
    super()
    @index_path = index_path
  end

  form do |f|
    f.fieldset_group(title: model.name,
                     description: helpers.t("two_factor_authentication.devices.totp.description")) do |fg|
      fg.text_field(
        name: :identifier,
        label: attribute_name(:identifier),
        required: true,
        caption: helpers.t("two_factor_authentication.devices.text_identifier")
      )
      fg.hidden(name: :otp_secret, value: model.otp_secret)
    end

    f.html_content do
      render(TwoFactorAuthentication::Devices::TotpQrCodeComponent.new(device: model))
    end

    f.group(layout: :horizontal) do |button_group|
      button_group.button(
        name: :cancel,
        tag: :a,
        label: helpers.t(:button_cancel),
        scheme: :default,
        href: @index_path
      ) do |button|
        button.with_leading_visual_icon(icon: :x)
        helpers.t(:button_cancel)
      end
      button_group.submit(name: :submit, label: helpers.t(:button_continue), scheme: :primary) do |button|
        button.with_leading_visual_icon(icon: :check)
        helpers.t(:button_continue)
      end
    end
  end
end
