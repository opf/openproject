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

module WorkPackages
  class MoveDialogComponent < ApplicationComponent
    include OpTurbo::Streamable
    include WorkPackages::MoveDialogs::Descendants

    DIALOG_ID = "wp-move-dialog"

    attr_reader :work_package

    def initialize(work_package:, back_url: nil)
      super
      @work_package = work_package
      @back_url = back_url
    end

    private

    def id = DIALOG_ID

    def i18n_scope = "work_packages.move_dialog"

    def move_roots = [work_package]

    def title = t_shared("descendants_choice.title")

    def description = t_dialog("descendants_choice.heading")

    def confirm_move_path
      helpers.confirm_move_work_packages_path(ids: [work_package.id], back_url: @back_url)
    end
  end
end
