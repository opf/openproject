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

module Admin
  module Settings
    class MailNotificationsSettingForm < ApplicationForm
      include ::Settings::FormHelper

      settings_form do |f|
        if @deliveries
          f.text_field name: :mail_from, input_width: :medium
          f.check_box name: :bcc_recipients
          f.check_box name: :plain_text_mail
          f.select_list name: :emails_salutation,
                        values: [
                          [User.human_attribute_name(:firstname), :firstname],
                          [I18n.t("mail.salutation_full_name"), :name]
                        ],
                        input_width: :medium

          f.fieldset_group(title: "#{I18n.t(:setting_emails_header)} & #{I18n.t(:setting_emails_footer)}", mt: 4) do |fg|
            fg.multi_language_text_select(name: :emails_header)
            fg.multi_language_text_select(name: :emails_footer)
          end
        end

        unless OpenProject::Configuration["email_delivery_configuration"] == "legacy"
          email_methods = %i[smtp sendmail]
          email_methods += [:letter_opener] if Rails.env.development?

          f.fieldset_group(title: I18n.t(:text_setup_mail_configuration), mt: 4) do |fg|
            fg.select_list(
              name: :email_delivery_method,
              values: email_methods.map { |m| [m.to_s, m] },
              input_width: :small,
              data: {
                show_when_value_selected_target: "cause",
                target_name: "email_delivery_method_settings"
              }
            )
          end

          f.group(
            hidden: { true => Setting.email_delivery_method != :smtp },
            data: {
              show_when_value_selected_target: "effect",
              target_name: "email_delivery_method_settings",
              value: "smtp"
            }
          ) do |smtp|
            smtp.text_field(name: :smtp_address, input_width: :medium)
            smtp.text_field(name: :smtp_port, type: :number, input_width: :xsmall)
            smtp.text_field(name: :smtp_domain, input_width: :medium)
            smtp.select_list(name: :smtp_authentication,
                             values: %i[none plain login cram_md5].map { |m| [m.to_s, m] },
                             input_width: :small)
            smtp.text_field(name: :smtp_user_name, input_width: :medium)
            smtp.text_field(name: :smtp_password, input_width: :medium)
            smtp.check_box(name: :smtp_enable_starttls_auto)
            smtp.check_box(name: :smtp_ssl)
          end

          f.group(
            hidden: { true => Setting.email_delivery_method != :sendmail },
            data: {
              show_when_value_selected_target: "effect",
              target_name: "email_delivery_method_settings",
              value: "sendmail"
            }
          ) do |sendmail|
            sendmail.text_field(name: :sendmail_location)
            sendmail.text_field(name: :sendmail_arguments)
          end
        end

        f.submit
      end

      def initialize(deliveries:)
        super()

        @deliveries = deliveries
      end
    end
  end
end
