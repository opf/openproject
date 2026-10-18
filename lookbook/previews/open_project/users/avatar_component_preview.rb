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

module OpenProject::Users
  # @logical_path OpenProject/Users
  class AvatarComponentPreview < Lookbook::Preview
    # Renders a user avatar using the OpenProject opce-principal web component.
    # Please note that hover cards will not be displayed in the preview, since the necessary Javascript controller
    # is not loaded.
    # @param size select { choices: [default, medium, mini] }
    # @param link toggle
    # @param show_name toggle
    # @param hover_card toggle
    def default(size: :default, link: true, show_name: true, hover_card: true)
      user = FactoryBot.build_stubbed(:user)
      render(Users::AvatarComponent.new(user:, size:, link:, show_name:,
                                        hover_card: { active: hover_card }))
    end

    def sizes
      user = FactoryBot.build_stubbed(:user)
      render_with_template(locals: { user: })
    end

    # Shows an avatar from a given image URL instead of the avatar of the user.
    # Use these parameters to show a preview of avatar changes that are not saved yet.
    #
    # - `avatar_image_url`: The image to show. Usually a blob, data, or API URL.
    # - `avatar_fallback_image_url`: The image to show if the first image does not load.
    #   If you do not set it, the component loads the generated initials of the user from the API.
    #
    # To see the fallback image, set `avatar_image_url` to a URL that does not load, for example `/missing.png`.
    # @param size select { choices: [default, medium, mini] }
    # @param avatar_image_url text
    # @param avatar_fallback_image_url text
    def image_overrides(size: :default,
                        avatar_image_url: preview_svg_url("#0969DA", "IM"),
                        avatar_fallback_image_url: preview_svg_url("#1A7F37", "FB"))
      user = FactoryBot.build_stubbed(:user)
      render(Users::AvatarComponent.new(user:, size:, link: false, hover_card: { active: false },
                                        avatar_image_url:, avatar_fallback_image_url:))
    end

    private

    def preview_svg_url(color, text)
      svg = OpenProject::Avatars::InitialsSvg.build_svg(color, text)
      "data:image/svg+xml;charset=UTF-8,#{ERB::Util.url_encode(svg)}"
    end
  end
end
