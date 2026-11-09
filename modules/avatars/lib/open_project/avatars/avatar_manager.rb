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

module OpenProject
  module Avatars
    module AvatarManager
      class << self
        def settings
          (Setting.plugin_openproject_avatars || {}).with_indifferent_access
        end

        def gravatar_enabled?
          val = settings[:enable_gravatars]
          ActiveModel::Type::Boolean.new.cast(val)
        end

        def local_avatars_enabled?
          val = settings[:enable_local_avatars]
          ActiveModel::Type::Boolean.new.cast(val)
        end

        def available_types(principal)
          types = %w[initials]
          types.unshift("image") if local_avatars_enabled?
          types.unshift("gravatar") if principal.is_a?(User) && gravatar_enabled?
          types
        end

        def avatar_type_for(principal)
          types = available_types(principal)
          return types.first if types.one?
          return default_avatar_type_for(principal) if principal.avatar_type.blank?

          types.include?(principal.avatar_type) ? principal.avatar_type : "initials"
        end

        private

        def default_avatar_type_for(principal)
          return "image" if local_avatars_enabled? && principal.local_avatar_attachment
          return "initials" if principal.avatar_text.present?
          return "gravatar" if principal.is_a?(User) && gravatar_enabled?

          "initials"
        end
      end
    end
  end
end
