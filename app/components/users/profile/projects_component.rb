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

module Users
  module Profile
    class ProjectsComponent < ApplicationComponent # rubocop:disable OpenProject/AddPreviewForViewComponent
      include ApplicationHelper
      include OpTurbo::Streamable
      include OpPrimer::ComponentHelpers
      include RolesHelper

      def initialize(user:)
        super()

        @user = user
        @memberships = visible_memberships.order("projects.name ASC")
      end

      def render?
        @memberships.any?
      end

      private

      # The .visible scope cannot simply be concatenated to the memberships as .memberships
      # has an include and an order which for whatever reason also gets applied to the
      # Project.allowed_to parts concatenated by a UNION, and an order inside a UNION is
      # not allowed in postgres.
      def visible_memberships
        memberships = @user.memberships.of_any_project

        return memberships if @user == User.current

        memberships.where(id: Member.visible(User.current))
      end
    end
  end
end
