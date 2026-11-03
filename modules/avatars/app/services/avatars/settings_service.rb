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
  class SettingsService
    def initialize(principal:, user:)
      @principal = principal
      @user = user
    end

    def call(attributes:, file: nil)
      type = attributes[:avatar_type]
      return failure(:avatar_type, :inclusion) unless available_type?(type)
      return failure(:base, I18n.t("avatars.image_required")) if type == "image" && file.blank? && !local_avatar?

      result = nil
      @principal.class.transaction do
        result = update_with_image(attributes, file)
        raise ActiveRecord::Rollback unless result.success?

        @principal.touch
      end

      result
    end

    private

    def failure(attribute, error)
      ServiceResult.failure(result: @principal).tap { |result| result.errors.add(attribute, error) }
    end

    def available_type?(type)
      OpenProject::Avatars::AvatarManager.available_types(@principal).include?(type)
    end

    def local_avatar?
      @principal.local_avatar_attachment.present?
    end

    def update_with_image(attributes, file)
      result = update_preferences(attributes)
      if result.success? && file.present? && attributes[:avatar_type] == "image"
        UpdateService.new(@principal).replace(file)
      else
        result
      end
    end

    def update_preferences(attributes)
      if @principal.is_a?(User)
        Users::UpdateService.new(model: @principal, user: @user).call(pref: attributes)
      else
        Groups::UpdateService.new(model: @principal, user: @user).call(attributes)
      end
    end
  end
end
