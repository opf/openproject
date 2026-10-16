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

module Projects
  class CopyOptionsForm < ApplicationForm
    extend Dry::Initializer

    option :dependencies_label

    form do |f|
      # Primer, unlike Rails' check_box helper, does not render this auxilary hidden field for us.
      f.hidden name: "copy_options[dependencies][]", value: "", scope_name_to_model: false

      f.check_box_group(name: :dependencies, label: dependencies_label) do |group|
        CopyOptions.all_dependencies.each do |value, label|
          group.check_box label:, value:
        end
      end

      f.check_box_group(label: Notification.model_name.human(count: 2)) do |group|
        group.check_box name: :send_notifications, label: I18n.t("label_project_copy_notifications")
      end
    end
  end
end
