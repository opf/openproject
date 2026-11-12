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
  class InitialsForm < ApplicationForm
    form do |f|
      f.text_field(
        name: :avatar_text,
        id: "avatar_text",
        label: I18n.t("avatars.label_avatar_text"),
        caption: I18n.t("avatars.text_avatar_text"),
        value: @principal.avatar_text,
        placeholder: OpenProject::Avatars::InitialsSvg.initials_for(@principal.name),
        input_width: :small,
        data: {
          "avatars--settings-target": "text",
          action: "input->avatars--settings#update compositionend->avatars--settings#update"
        }
      )
      f.group(layout: :horizontal, classes: "avatars--color-input-group") do |row|
        row.color_field(
          name: :avatar_color,
          label: I18n.t("avatars.label_background_color"),
          caption: I18n.t("avatars.background_color_hint"),
          value: @principal.avatar_color,
          placeholder: "#AABBCC",
          input_width: :small,
          full_width: false,
          data: {
            "avatars--settings-target": "color",
            action: "input->avatars--settings#update change->avatars--settings#update"
          }
        )
        row.html_content do
          render(
            Primer::Beta::IconButton.new(
              icon: :sync,
              type: :button,
              mt: 4,
              aria: { label: I18n.t("avatars.randomize_color") },
              test_selector: "avatar-randomize-color",
              data: { action: "avatars--settings#randomizeColor" }
            )
          )
        end
      end
    end

    def initialize(principal:)
      super()
      @principal = principal
    end
  end
end
