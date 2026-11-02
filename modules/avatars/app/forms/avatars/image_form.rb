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

module Avatars
  class ImageForm < ApplicationForm
    form do |f|
      f.file_field(
        name: :file,
        id: "avatar_file_input",
        label: I18n.t(:label_choose_avatar),
        caption: I18n.t("avatars.image_hint"),
        accept: "image/jpeg,image/png,image/gif",
        preview_url: @image_url,
        delete_path: (@target_avatar_path if @image_url.present?),
        delete_button_arguments: {
          data: {
            turbo: true,
            turbo_method: :delete,
            turbo_confirm: I18n.t(:are_you_sure_delete_avatar),
            test_selector: "avatar-delete-link"
          }
        },
        data: { "avatars--settings-target": "file", action: "change->avatars--settings#upload" },
        invalid_file_message: I18n.t(:wrong_file_format),
        error_data: { "avatars--settings-target": "uploadError" }
      )
    end

    def initialize(image_url:, target_avatar_path:)
      super()
      @image_url = image_url
      @target_avatar_path = target_avatar_path
    end
  end
end
