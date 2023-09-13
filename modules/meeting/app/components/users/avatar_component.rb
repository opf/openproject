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

module Users
  class AvatarComponent < ApplicationComponent
    include ApplicationHelper
    include AvatarHelper
    include OpPrimer::ComponentHelpers

    def initialize(user:, show_name: true, link: true, avatar_system_attribues: {}, text_system_attributes: {})
      super

      @user = user
      @show_name = show_name
      @link = link
      @avatar_system_attribues = avatar_system_attribues
      @text_system_attributes = text_system_attributes
    end

    def render?
      @user.present?
    end

    # build_principal_avatar_tag(@user, hide_name: true) cannot be used
    # once the list or item gets updated by hotwire, the avatar is not rendered anymore
    def call
      flex_layout(align_items: :center) do |flex|
        if defined?(@user.local_avatar_attachment) && @user.local_avatar_attachment.present?
          flex.with_column(mr: 2) do
            avatar_partial
          end
        else
          flex.with_column(mr: 2) do
            avatar_fallback_partial
          end
        end
        if @show_name
          flex.with_column do
            if @link
              user_link_partial
            else
              user_name_partial
            end
          end
        end
      end
    end

    private

    def user_link_partial
      render(Primer::Beta::Link.new(**{
        href: user_path(@user),
        underline: false,
        scheme: :primary,
        target: "_blank"
      }.merge(@text_system_attributes))) do
        user_name_partial
      end
    end

    def user_name_partial
      render(Primer::Beta::Truncate.new) do |component|
        component.with_item(**{
          max_width: 150,
          expandable: true,
          font_size: :small
        }.merge(@text_system_attributes)) do
          @user.name
        end
      end
    end

    def avatar_partial
      render(Primer::Beta::Avatar.new(**{
        src: avatar_url(@user),
        alt: @user.name, size: 16
      }.merge(@avatar_system_attribues)))
    end

    def avatar_fallback_partial
      render(Primer::Beta::Octicon.new(
               **{
                 color: :subtle,
                 size: :small,
                 icon: "feed-person",
                 'aria-label': "Responsible"
               }.merge(@avatar_system_attribues)
             ))
    end
  end
end
