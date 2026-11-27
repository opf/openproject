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
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module ITSM
  module ProjectSettings
    class OutgoingMailboxConfigurationForm < ApplicationForm
      form do |f|
        f.text_field(name: :username,
                     label: OutgoingMailbox.human_attribute_name(:username),
                     required: true)

        f.text_field(name: :password,
                     label: OutgoingMailbox.human_attribute_name(:password),
                     required: true)

        f.text_field(name: :sender_name,
                     label: OutgoingMailbox.human_attribute_name(:sender_name),
                     required: true)

        f.text_field(name: :sender_email,
                     label: OutgoingMailbox.human_attribute_name(:sender_email),
                     required: true,
                     caption: I18n.t("itsm.project_settings.forms.outgoing_mail_configuration_form_component.sender_email_caption"))

        f.group(layout: :horizontal) do |button_group|
          button_group.submit(name: :submit, label: I18n.t(:button_save), scheme: :primary)

          if model.persisted?
            button_group.button(name: :cancel,
                                href: helpers.project_settings_helpdesk_path,
                                tag: :a,
                                label: I18n.t(:button_cancel),
                                scheme: :default)
          end
        end
      end
    end
  end
end
