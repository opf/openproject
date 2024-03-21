#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

module ConfirmationDialogHelper
  ##
  # Show an angular modal confirmation dialog using the augmented
  # ConfirmationDialogService
  def augmented_confirmation_dialog(
    title: nil,
    text: nil,
    danger_zone: false,
    show_list_data: false,
    refresh_on_cancel: false,
    list_title: nil,
    warning_text: nil,
    button_continue: nil,
    button_cancel: nil,
    icon_continue: nil,
    divider: nil,
    passed_data: nil
  )
    {
      'augmented-confirm-dialog': {
        text: {
          title:,
          text:,
          button_continue:,
          button_cancel:
        }.compact,
        dangerHighlighting: danger_zone,
        divideContent: divider,
        listTitle: list_title,
        warningText: warning_text,
        passedData: passed_data,
        showListData: show_list_data,
        refreshOnCancel: refresh_on_cancel,
        icon: {
          continue: icon_continue
        }.compact
      }.to_json
    }
  end
end
