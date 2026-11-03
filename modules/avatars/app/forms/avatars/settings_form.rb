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
  class SettingsForm < ApplicationForm
    form do |f|
      f.radio_button_group(name: :avatar_type, label: I18n.t("avatars.label_option")) do |group|
        manager.available_types(@principal).each do |type|
          group.radio_button(
            value: type,
            label: I18n.t("avatars.types.#{type}.label"),
            caption: caption(type),
            checked: selected_type == type,
            data: { "avatars--settings-target": "type", action: "change->avatars--settings#update" }
          ) do |button|
            nested_option(button, type)
          end
        end
      end
    end

    def initialize(principal:, target_avatar_path:, image_url:)
      super()
      @principal = principal
      @target_avatar_path = target_avatar_path
      @image_url = image_url
    end

    private

    def nested_option(button, type)
      case type
      when "image"
        button.nested_form(**option_arguments(type)) do |builder|
          ImageForm.new(builder, image_url: @image_url, target_avatar_path: @target_avatar_path)
        end
      when "initials"
        button.nested_form(**option_arguments(type)) { |builder| InitialsForm.new(builder, principal: @principal) }
      end
    end

    def option_arguments(type)
      { classes: "mt-2", hidden: selected_type != type, data: { "avatars--settings-target": "panel", type: } }
    end

    def caption(type)
      description = I18n.t("avatars.types.#{type}.description")
      return description unless type == "gravatar"

      link = helpers.static_link_to(:gravatar, label: I18n.t("avatars.manage_gravatar"))
      helpers.safe_join([description, link], helpers.tag.br)
    end

    def selected_type
      @selected_type ||= manager.avatar_type_for(@principal)
    end

    def manager
      OpenProject::Avatars::AvatarManager
    end
  end
end
