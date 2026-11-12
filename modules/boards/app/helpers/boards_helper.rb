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

module BoardsHelper
  BoardTypeAttributes = Struct.new(:radio_button_value,
                                   :title,
                                   :description,
                                   :image_path)

  def board_types
    [
      build_board_type_attributes("basic", "lists"),
      build_board_type_attributes("status", "status"),
      build_board_type_attributes("assignee", "assignees"),
      build_board_type_attributes("version", "version"),
      build_board_type_attributes("subproject", "subproject"),
      build_board_type_attributes("subtasks", "parent-child")
    ]
  end

  def build_board_type_attributes(type_name, image_name)
    BoardTypeAttributes.new(type_name,
                            I18n.t("boards.board_type_attributes.#{type_name}"),
                            I18n.t("boards.board_type_descriptions.#{type_name}"),
                            "assets/images/board_creation_modal/#{image_name}.svg")
  end

  def global_board_create_context?
    global_board_new_action? || global_board_create_action?
  end

  def global_board_new_action?
    request.path == new_work_package_board_path
  end

  def global_board_create_action?
    request.path == work_package_boards_path && controller.params[:project_id].blank?
  end
end
