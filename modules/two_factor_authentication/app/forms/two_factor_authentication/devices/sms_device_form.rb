# frozen_string_literal: true

class TwoFactorAuthentication::Devices::SmsDeviceForm < ApplicationForm
  def initialize(index_path:)
    super()
    @index_path = index_path
  end

  form do |f|
    f.fieldset_group(title: model.name,
                     description: helpers.t("two_factor_authentication.devices.sms.description")) do |fg|
      fg.text_field(
        name: :identifier,
        label: attribute_name(:identifier),
        required: true,
        caption: helpers.t("two_factor_authentication.devices.text_identifier")
      )
      fg.text_field(
        name: :phone_number,
        label: ::TwoFactorAuthentication::Device::Sms.human_attribute_name(:phone_number),
        required: true,
        caption: helpers.t("notice_phone_number_format")
      )
    end

    available_channels = model.class.available_channels_in_strategy
    if available_channels.length > 1
      f.fieldset_group(title: helpers.t(:label_otp_channel)) do |fg|
        fg.radio_button_group(name: :channel) do |radio_group|
          available_channels.each do |channel|
            radio_group.radio_button(value: channel, label: helpers.t("button_otp_by_#{channel}"))
          end
        end
      end
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
