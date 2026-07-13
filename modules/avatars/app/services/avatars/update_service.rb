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
require "mini_magick"

module ::Avatars
  class UpdateService
    attr_reader :user

    def initialize(user)
      @user = user
    end

    def replace(avatar) # rubocop:disable Metrics/AbcSize
      if avatar.nil?
        return ServiceResult.failure.tap do |_result|
          return error_result(I18n.t(:empty_file_error))
        end
      end

      content_type = OpenProject::ContentTypeDetector.new(avatar.path).detect
      unless allowed_content_types.include?(content_type)
        return error_result(I18n.t(:wrong_file_format))
      end

      if avatar.size > 2.5.megabytes
        return error_result(I18n.t(:error_image_size))
      end

      image = MiniMagick::Image.open(avatar.path)
      if image.dimensions.any? { |dim| dim > 128 }
        return error_result(I18n.t(:error_image_size))
      end

      @user.local_avatar_attachment = avatar
      ServiceResult.success(result: I18n.t(:message_avatar_uploaded))
    rescue StandardError => e
      Rails.logger.error "Failed to update avatar of user##{user.id}: #{e}"
      error_result(I18n.t(:error_image_upload))
    end

    def destroy
      current_attachment = @user.local_avatar_attachment
      if current_attachment && current_attachment.destroy
        @user.reload
        ServiceResult.success(result: I18n.t(:avatar_deleted))
      else
        error_result(I18n.t(:unable_to_delete_avatar))
      end
    rescue StandardError => e
      Rails.logger.error "Failed to delete avatar of user##{user.id}: #{e}"
      error_result(e.message)
    end

    private

    def allowed_content_types
      %w[image/jpeg image/png image/gif]
    end

    def error_result(message)
      ServiceResult.failure.tap do |result|
        result.errors.add(:base, message)
      end
    end
  end
end
