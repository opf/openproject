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

class Setting
  module MailSettings
    ##
    # Reload the currently configured mailer configuration
    def reload_mailer_settings!
      ActionMailer::Base.perform_deliveries = true
      ActionMailer::Base.delivery_method = Setting.email_delivery_method if Setting.email_delivery_method

      case Setting.email_delivery_method
      when :smtp
        reload_smtp_settings!
      when :sendmail
        ActionMailer::Base.sendmail_settings = {
          location: Setting.sendmail_location,
          arguments: Setting.sendmail_arguments
        }
      end
    rescue StandardError => e
      Rails.logger.error "Unable to set ActionMailer settings (#{e.message}). " \
                         "Email sending will most likely NOT work."
    end

    private

    # rubocop:disable Metrics/AbcSize
    def reload_smtp_settings!
      # Correct smtp settings when using authentication :none
      authentication = Setting.smtp_authentication.try(:to_sym)
      keys = %i[address port domain authentication user_name password]
      if authentication == :none
        # Rails Mailer will croak if passing :none as the authentication.
        # Instead, it requires to be removed from its settings
        ActionMailer::Base.smtp_settings.delete :user_name
        ActionMailer::Base.smtp_settings.delete :password
        ActionMailer::Base.smtp_settings.delete :authentication

        keys = %i[address port domain]
      end

      keys.each do |setting|
        value = Setting["smtp_#{setting}"]
        if value.present?
          ActionMailer::Base.smtp_settings[setting] = value
        else
          ActionMailer::Base.smtp_settings.delete setting
        end
      end

      ActionMailer::Base.smtp_settings[:enable_starttls_auto] = Setting.smtp_enable_starttls_auto?
      ActionMailer::Base.smtp_settings[:ssl] = Setting.smtp_ssl?
      ActionMailer::Base.smtp_settings[:open_timeout] = Setting.smtp_timeout
      ActionMailer::Base.smtp_settings[:read_timeout] = Setting.smtp_timeout

      Setting.smtp_openssl_verify_mode.tap do |mode|
        ActionMailer::Base.smtp_settings[:openssl_verify_mode] = mode unless mode.nil?
      end
    end
    # rubocop:enable Metrics/AbcSize
  end
end
