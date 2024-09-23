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

module Storages
  class StoragesMailer < ApplicationMailer
    layout "mailer"

    include MessagesHelper
    include MailNotificationHelper

    helper_method :message_url
    helper :mail_notification

    def notify_unhealthy(admin, storage)
      @admin = admin
      @storage = storage
      @reason = storage.health_reason
      @url = edit_admin_settings_storage_url(storage)
      subject = I18n.t("mail.storages.health.unhealthy.subject", name: @storage.name)
      mail(to: admin, subject:)
    end

    def notify_healthy(admin, storage, reason)
      @admin = admin
      @storage = storage
      @reason = reason
      @url = edit_admin_settings_storage_url(storage)
      subject = I18n.t("mail.storages.health.healthy.subject", name: @storage.name)
      mail(to: admin, subject:)
    end
  end
end
