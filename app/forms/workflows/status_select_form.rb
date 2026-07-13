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

module Workflows
  class StatusSelectForm < ApplicationForm
    def initialize(all_statuses:, current_statuses:, type:, tab:, dialog_id:)
      super()
      @all_statuses = all_statuses
      @current_statuses = current_statuses
      @type = type
      @tab = tab
      @dialog_id = dialog_id
    end

    form do |f|
      f.hidden(name: :type_id, value: @type.id)
      f.hidden(name: :tab, value: @tab || "always")
      @current_statuses.each { |status| f.hidden(name: "original_status_ids[]", value: status.id) }

      f.autocompleter(
        name: :status_ids,
        label: I18n.t("admin.workflows.statuses_dialog.label"),
        caption: I18n.t("admin.workflows.statuses_dialog.caption"),
        autocomplete_options: {
          multiple: true,
          decorated: true,
          closeOnSelect: false,
          clearable: false,
          appendTo: "##{@dialog_id}"
        }
      ) do |list|
        @all_statuses.each do |status|
          list.option(
            label: status.name,
            value: status.id,
            selected: @current_statuses.include?(status)
          )
        end
      end
    end
  end
end
