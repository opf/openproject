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

class My::AlertsForm < ApplicationForm
  form do |f|
    f.fieldset_group(title: helpers.t("activerecord.attributes.user_preference.header_alerts"), mt: 3) do |fg|
      fg.check_box name: :warn_on_leaving_unsaved,
                   label: helpers.t("activerecord.attributes.user_preference.warn_on_leaving_unsaved")

      fg.check_box name: :auto_hide_popups,
                   label: helpers.t("activerecord.attributes.user_preference.auto_hide_popups"),
                   caption: helpers.t("activerecord.attributes.user_preference.auto_hide_popups_caption")

      fg.submit(name: :submit, label: helpers.t("activerecord.attributes.user_preference.button_update_alerts"), scheme: :default)
    end
  end
end
