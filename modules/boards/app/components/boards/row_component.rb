# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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

module Boards
  class RowComponent < ::RowComponent
    def project_id
      helpers.link_to_project model.project, {}, {}, false
    end

    def name
      link_to model.name, project_work_package_boards_path(model.project, model)
    end

    def created_at
      safe_join([helpers.format_date(model.created_at), helpers.format_time(model.created_at, false)], " ")
    end

    def type
      case model.board_type
      when :action
        t('boards.board_types.action', attribute: t(model.board_type_attribute, scope: 'boards.board_type_attributes'))
      else
        t('boards.board_types.free')
      end
    end
  end
end
