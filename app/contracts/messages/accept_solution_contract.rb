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

module Messages
  class AcceptSolutionContract < ::ModelContract
    def self.model
      Message
    end

    def self.can_accept?(user:, message:)
      message.parent_id.present? && user.logged? &&
        (message.parent.author_id == user.id || user.allowed_in_project?(:edit_messages, message.project))
    end

    attribute :accepted_solution

    validate :user_may_mark_solution

    private

    def user_may_mark_solution
      errors.add(:base, :error_unauthorized) unless self.class.can_accept?(user:, message: model)
    end
  end
end
