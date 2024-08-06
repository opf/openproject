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

module MeetingSections
  class UpdateContract < BaseContract
    validate :user_allowed_to_edit

    # We allow an empty title internally via create to mark an untitled/implicit section
    # but users should not be able to update it with an empty title through this contract
    validates :title, presence: true

    # Meeting agenda items can currently be only edited
    # through the project permission :manage_agendas
    # When MeetingRole becomes available, agenda items will
    # be edited through meeting permissions :manage_agendas
    def user_allowed_to_edit
      unless user.allowed_in_project?(:manage_agendas, model.project)
        errors.add :base, :error_unauthorized
      end
    end
  end
end
