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
    class ServerConfigurationForm < ApplicationForm
      form do |f|
        f.hidden(name: :name)
        f.hidden(name: :protocol)

        f.group(layout: :horizontal) do |input_group|
          input_group.text_field(name: :host,
                                 label: I18n.t("itsm.admin.server_configuration_form.name"),
                                 required: true)
          input_group.text_field(name: :port,
                                 type: :number,
                                 label: I18n.t("itsm.admin.server_configuration_form.port"),
                                 required: true)
        end

        f.group(layout: :horizontal) do |input_group|
          input_group.select_list(name: :encryption,
                                  label: I18n.t("itsm.admin.server_configuration_form.encryption"),
                                  input_width: :xsmall,
                                  required: true) do |encryptions|
            ITSM::MailServer.encryptions.each_key do |key|
              encryptions.option(value: key, label: key.upcase)
            end
          end
        end

        f.group(layout: :horizontal) do |button_group|
          button_group.submit(name: :submit, label: I18n.t(:button_save), scheme: :primary)
          button_group.button(name: :cancel,
                              href: helpers.close_server_configuration_itsm_admin_settings_path(server_protocol:),
                              tag: :a,
                              label: I18n.t(:button_cancel),
                              scheme: :default,
                              data: { turbo_stream: true })
        end
      end

      private

      def server_protocol = model.protocol
    end
  end
end
