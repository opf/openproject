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

module Statuses
  class RowComponent < ::RowComponent
    def status
      model
    end

    def name
      link_to status.name, edit_status_path(status)
    end

    def default?
      checkmark(status.is_default?)
    end

    def closed?
      checkmark(status.is_closed?)
    end

    def readonly?
      checkmark(status.is_readonly?)
    end

    def excluded_from_totals?
      checkmark(status.excluded_from_totals?)
    end

    def color
      helpers.icon_for_color status.color
    end

    def done_ratio
      h(status.default_done_ratio)
    end

    def sort
      helpers.reorder_links "status",
                            { action: "update", id: status },
                            method: :patch
    end

    def button_links
      [
        delete_link
      ]
    end

    def delete_link
      link_to(
        helpers.op_icon("icon icon-delete"),
        status_path(status),
        method: :delete,
        data: { confirm: I18n.t(:text_are_you_sure) },
        title: t(:button_delete)
      )
    end
  end
end
