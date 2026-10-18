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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

class My::Notifications::WorkPackageSettingsForm < ApplicationForm
  form do |f|
    f.fieldset_group(
      title: helpers.t("my_account.notifications.work_package_settings.title"),
      description: helpers.t("my_account.notifications.work_package_settings.description"),
      mt: 3
    ) do |fg|
      fg.check_box(
        name: :auto_mark_wp_as_read,
        label: helpers.t("my_account.notifications.work_package_settings.auto_mark_wp_as_read.label"),
        caption: helpers.t("my_account.notifications.work_package_settings.auto_mark_wp_as_read.caption"),
        data: { test_selector: "pref-auto-mark-wp-as-read" }
      )

      fg.check_box(
        name: :mark_wp_as_read_on_commenting,
        label: helpers.t("my_account.notifications.work_package_settings.mark_wp_as_read_on_commenting.label"),
        caption: helpers.t("my_account.notifications.work_package_settings.mark_wp_as_read_on_commenting.caption"),
        data: { test_selector: "pref-mark-wp-as-read-on-commenting" }
      )

      fg.submit(name: :submit, label: helpers.t("button_save"), scheme: :default)
    end
  end
end
