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

module ITSM
  module Admin
    class SettingsController < ApplicationController
      include OpTurbo::ComponentStream

      layout "admin"

      menu_item :helpdesk

      before_action :require_feature
      before_action :require_admin

      def show
        @helpdesk_enabled = Setting.helpdesk_enabled?
        @helpdesk_feature_writable = Setting.helpdesk_enabled_writable?

        @wizard = wizard
      end

      def update
        p = allowed_params
        server = MailServer.find_or_initialize_by(protocol: p[:protocol])
        # TODO: Add contracts and services
        success = server.update(p.except(:protocol))

        if success
          close_server_configuration_form(protocol: server.protocol)
        else
          update_server_configuration_form(server:)
        end
      end

      def enable_helpdesk
        enabled = ActiveModel::Type::Boolean.new.cast(params[:value])
        Setting.helpdesk_enabled = enabled

        update_via_turbo_stream(component: ITSM::Admin::HelpdeskSettingsComponent.new(enabled:, wizard:))
        respond_with_turbo_streams
      end

      def require_feature
        render_404 unless OpenProject::FeatureDecisions.helpdesk_active?
      end

      def edit_server_configuration
        protocol = params[:server_protocol].to_s
        server = MailServer.find_or_initialize_by(protocol:) do |server|
          server.name = derive_server_name(protocol)
          server.encryption = "tls"
          server.port = derive_default_port(protocol)
        end

        update_server_configuration_form(server:)
      end

      def close_server_configuration
        close_server_configuration_form(protocol: params[:server_protocol].to_s)
      end

      private

      def wizard
        ITSM::Wizard.new(model: nil)
      end

      def allowed_params
        params.expect(itsm_mail_server: %i[name host port protocol encryption])
      end

      def derive_server_name(protocol)
        "#{protocol.upcase} Mail Server"
      end

      def derive_default_port(protocol)
        case protocol
        when "imap"
          993
        when "smtp"
          465 # TLS is default, hence the TLS port is default
        end
      end

      def update_server_configuration_form(server:)
        case server.protocol
        when "imap"
          update_via_turbo_stream(component: Forms::ImapServerConfigurationFormComponent.new(server))
        when "smtp"
          update_via_turbo_stream(component: Forms::SmtpServerConfigurationFormComponent.new(server))
        end

        respond_with_turbo_streams
      end

      def close_server_configuration_form(protocol:)
        case protocol
        when "imap"
          update_via_turbo_stream(component: ITSM::Admin::ImapServerConfigurationComponent.new)
        when "smtp"
          update_via_turbo_stream(component: ITSM::Admin::SmtpServerConfigurationComponent.new)
        end

        respond_with_turbo_streams
      end
    end
  end
end
