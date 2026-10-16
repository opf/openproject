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

module Header
  class WhatsNewComponent < ApplicationComponent
    include OpTurbo::Streamable

    IMAGE_EXTENSIONS = %w[png jpg jpeg gif svg].freeze

    delegate :items, :video_url, to: :@release

    def initialize(release: WhatsNew::Release.current, user: User.current, in_dialog: false)
      super()
      @release = release
      @user = user
      @in_dialog = in_dialog
    end

    def wrapper_uniq_by
      "dialog" if @in_dialog
    end

    def show_title?
      !@in_dialog
    end

    def title
      t("header.whats_new.title", version: @release.version)
    end

    def seen_url
      seen_header_whats_new_path unless @release.seen?(@user)
    end

    def show_header_row?
      show_title? || video_url.present?
    end

    def image
      return @image if defined?(@image)

      @image = IMAGE_EXTENSIONS
        .map { |extension| "#{@release.version_key}_whats_new.#{extension}" }
        .detect { |name| helpers.has_rails_asset?(name) }
    end

    private

    def unread_keys
      @unread_keys ||= @release.unread_keys(@user)
    end
  end
end
