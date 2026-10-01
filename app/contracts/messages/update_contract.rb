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

module Messages
  class UpdateContract < BaseContract
    attribute :forum_id, permission: :edit_messages
    attribute :locked, permission: :edit_messages
    attribute :sticky, permission: :edit_messages

    validate :moving_message_to_another_forum

    private

    def moving_message_to_another_forum
      return if !model.forum_id_changed?
      return if model.forum_id_was.nil?

      old_forum = Forum.find_by(id: model.forum_id_was)
      return if old_forum.nil?

      return if old_forum.project_id == model.forum.project_id

      errors.add(:forum_id, :cannot_move_message_to_forum_of_different_project)
    end
  end
end
