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
  class FormSectionComponent < ApplicationComponent
    DIALOG_ID = "avatar-settings-dialog"
    FORM_ID = "avatar-settings-form"

    delegate :avatar_color, :avatar_text, to: :@principal

    def initialize(principal:, target_avatar_path:, avatar_settings_path:)
      super()
      @principal = principal
      @target_avatar_path = target_avatar_path
      @avatar_settings_path = avatar_settings_path
    end

    def avatar_type
      manager.avatar_type_for(@principal)
    end

    def types
      manager.available_types(@principal)
    end

    def initials
      OpenProject::Avatars::InitialsSvg.initials_for(@principal.name)
    end

    def automatic_color
      "hsl(#{OpenProject::Avatars::InitialsSvg.hue_for("#{@principal.id}#{@principal.name}")}, 50%, 30%)"
    end

    def gravatar_url
      helpers.build_gravatar_image_url(@principal) if types.include?("gravatar")
    end

    def image_url
      return unless helpers.local_avatar?(@principal)

      principal_type = API::V3::Principals::PrincipalType.for(@principal)
      "#{API::V3::Utilities::PathHelper::ApiV3Path.send(principal_type, @principal.id)}/avatar?source=image"
    end

    def preview_svg
      text = avatar_type == "initials" ? avatar_text.presence || initials : initials
      OpenProject::Avatars::InitialsSvg.build_svg(avatar_color.presence || automatic_color, text)
    end

    def preview_fallback_image_url
      "data:image/svg+xml;charset=UTF-8,#{ERB::Util.url_encode(preview_svg)}"
    end

    def preview_image_url
      source = case avatar_type
               when "image" then image_url
               when "gravatar" then gravatar_url
               end
      source.presence || preview_fallback_image_url
    end

    private

    def manager
      OpenProject::Avatars::AvatarManager
    end
  end
end
