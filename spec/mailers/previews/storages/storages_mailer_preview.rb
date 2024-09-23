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
  class StoragesMailerPreview < ActionMailer::Preview
    # Preview emails at http://localhost:3000/rails/mailers/storages/storages_mailer
    def notify_unhealthy
      admin_user = FactoryBot.build_stubbed(:admin)
      storage = FactoryBot.build_stubbed(:nextcloud_storage)

      ::Storages::StoragesMailer.notify_unhealthy(admin_user, storage)
    end

    def notify_healthy
      admin_user = FactoryBot.build_stubbed(:admin)
      storage = FactoryBot.build_stubbed(:one_drive_storage)
      reason = "thou_shall_not_pass_error"

      ::Storages::StoragesMailer.notify_healthy(admin_user, storage, reason)
    end
  end
end
