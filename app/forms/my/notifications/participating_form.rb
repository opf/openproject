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

class My::Notifications::ParticipatingForm < ApplicationForm
  def initialize(show_submit: true)
    super()
    @show_submit = show_submit
  end

  form do |f|
    f.fieldset_group(title: helpers.t("my_account.notifications.participating.title"),
                     description: helpers.t("my_account.notifications.participating.description"),
                     mt: 2) do |fg|
      fg.check_box(
        name: :mentioned,
        label: helpers.t("my_account.notifications.participating.mentioned"),
        disabled: true,
        data: { test_selector: "global-notification-type-mentioned" },
        id: "op-notification-mentioned--#{SecureRandom.uuid}}"
      )
      fg.check_box(
        name: :watched,
        label: helpers.t("my_account.notifications.participating.watched"),
        disabled: true,
        data: { test_selector: "global-notification-type-watched" },
        id: "op-notification-watched--#{SecureRandom.uuid}}"
      )
      fg.check_box(
        name: :assignee,
        label: helpers.t("my_account.notifications.participating.assignee"),
        data: { test_selector: "global-notification-type-assignee" },
        id: "op-notification-assignee--#{SecureRandom.uuid}}"
      )
      fg.check_box(
        name: :responsible,
        label: helpers.t("my_account.notifications.participating.responsible"),
        data: { test_selector: "global-notification-type-responsible" },
        id: "op-notification-responsible--#{SecureRandom.uuid}}"
      )
      fg.check_box(
        name: :shared,
        label: helpers.t("my_account.notifications.participating.shared"),
        data: { test_selector: "global-notification-type-shared" },
        id: "op-notification-shared--#{SecureRandom.uuid}}"
      )

      if @show_submit
        fg.submit(name: :submit, label: helpers.t("my_account.notifications.participating.submit_button"),
                  scheme: :default)
      end
    end
  end
end
