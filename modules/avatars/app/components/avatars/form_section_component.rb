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

module Avatars
  class FormSectionComponent < ApplicationComponent
    include OpPrimer::FormHelpers

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

    def type_caption(type)
      description = t("avatars.types.#{type}.description")
      return description unless type == "gravatar"

      link = helpers.static_link_to(:gravatar, label: t("avatars.manage_gravatar"))
      helpers.safe_join([description, link], helpers.tag.br)
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

    def palette
      %w[#0969DA #1B4185 #1F883D #044F1E #9A6700 #BC4C00 #CF222E #8250DF #6639BA #6E7781]
    end

    private

    def manager
      OpenProject::Avatars::AvatarManager
    end
  end
end
