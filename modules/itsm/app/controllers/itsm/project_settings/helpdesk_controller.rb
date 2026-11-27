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
  module ProjectSettings
    class HelpdeskController < Projects::SettingsController
      include OpTurbo::ComponentStream

      menu_item :settings_helpdesk

      guard_feature_flag :helpdesk

      def show
        @wizard = ProjectHelpdeskWizard.new(model: @project)
        @wizard_step = active_wizard_step
        @helpdesk_enabled = Setting.helpdesk_enabled?
        @mail_server_configuration_complete = MailServer.imap.any? && MailServer.smtp.any?
      end

      def create_incoming_mailbox
        mailbox = IncomingMailbox.find_or_initialize_by(
          project: @project,
          mail_server: MailServer.imap.first,
        )

        success = mailbox.update(**incoming_mailbox_params)
        if success
          redirect_to action: :show
        else
          render_error_flash_message_via_turbo_stream(message: mailbox.errors.full_messages.join("\n"))
          respond_with_turbo_streams
        end
      end

      def create_outgoing_mailbox
        mailbox = OutgoingMailbox.find_or_initialize_by(
          project: @project,
          mail_server: MailServer.smtp.first,
        )

        success = mailbox.update(**outgoing_mailbox_params)
        if success
          redirect_to action: :show
        else
          render_error_flash_message_via_turbo_stream(message: mailbox.errors.full_messages.join("\n"))
          respond_with_turbo_streams
        end
      end

      private

      def incoming_mailbox_params
        params.expect(itsm_incoming_mailbox: %i[username email password])
      end

      def outgoing_mailbox_params
        params.expect(itsm_outgoing_mailbox: %i[username password sender_email sender_name])
      end

      def active_wizard_step
        from_params = params[:wizard_step]&.to_sym
        return from_params if from_params.present?

        open_step
      end

      def open_step
        if @project.helpdesk_incoming_mailboxes.none?
          :incoming_mail_configuration
        elsif @project.helpdesk_outgoing_mailboxes.none?
          :outgoing_mail_configuration
        else
          nil
        end
      end
    end
  end
end
