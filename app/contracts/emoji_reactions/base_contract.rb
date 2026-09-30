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

module EmojiReactions
  class BaseContract < ::ModelContract
    attribute :reaction
    attribute :user_id
    attribute :reactable_id
    attribute :reactable_type

    validate :manage_emoji_reactions_permission?
    validate :validate_user_exists
    validate :validate_acting_user
    validate :validate_reactable_exists

    def self.model = EmojiReaction

    private

    def validate_user_exists
      errors.add :user, :not_found unless User.exists?(model.user_id)
    end

    def validate_acting_user
      errors.add :user, :invalid unless model.user_id == user.id
    end

    def validate_reactable_exists
      errors.add :reactable, :not_found if model.reactable.blank?
    end

    def manage_emoji_reactions_permission?
      unless manage_emoji_reactions?
        errors.add :base, :error_unauthorized
      end
    end

    def manage_emoji_reactions?
      case model.reactable
      when WorkPackage
        user.allowed_in_work_package?(:add_work_package_comments, model.reactable)
      when Journal
        user.allowed_in_work_package?(:add_work_package_comments, model.reactable.journable)
      else
        false
      end
    end
  end
end
