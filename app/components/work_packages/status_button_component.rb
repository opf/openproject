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

class WorkPackages::StatusButtonComponent < OpPrimer::StatusButtonComponent
  attr_reader :work_package, :user

  def initialize(work_package:, user:, readonly: false, button_arguments: {}, menu_arguments: {})
    @work_package = work_package
    @user = user

    super(
      current_status: map_status(work_package.status),
      items: available_statuses,
      readonly:,
      button_arguments:,
      menu_arguments:
    )
  end

  def default_button_title
    I18n.t("js.label_edit_status")
  end

  def disabled?
    !user.allowed_in_project?(:edit_work_packages, work_package.project)
  end

  def available_statuses
    WorkPackages::UpdateContract
      .new(work_package, user)
      .assignable_statuses
      .map { |status| map_status(status) }
  end

  def map_status(status)
    icon = status.is_readonly? ? :lock : nil
    OpPrimer::StatusButtonOption.new(name: status.name, color_namespace: "status", color_ref: status.id, icon:)
  end
end
