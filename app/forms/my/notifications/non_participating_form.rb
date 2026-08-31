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

class My::Notifications::NonParticipatingForm < ApplicationForm
  def initialize(show_submit: true)
    super()
    @show_submit = show_submit
  end

  form do |f|
    f.fieldset_group(title: helpers.t("my_account.notifications.non_participating.title"),
                     description: helpers.t("my_account.notifications.non_participating.description"),
                     mt: 3) do |fg|
      NotificationSetting.non_participating_settings.each do |setting|
        fg.check_box(
          name: setting,
          label: helpers.t("my_account.notifications.non_participating.#{setting}"),
          data: { test_selector: "global-notification-type-#{setting}" },
          id: "op-notification-type-#{setting}--#{SecureRandom.uuid}}"
        )
      end

      if @show_submit
        fg.submit(name: :submit, label: helpers.t("my_account.notifications.non_participating.submit_button"),
                  scheme: :default)
      end
    end
  end
end
