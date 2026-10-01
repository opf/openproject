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
  module NonWorkingTimes
    class DialogComponent < ApplicationComponent
      include OpTurbo::Streamable
      include OpPrimer::ComponentHelpers

      DIALOG_ID = "non-working-time-dialog"

      attr_reader :user, :non_working_time

      def initialize(user:, non_working_time:, **)
        super(nil, **)
        @user = user
        @non_working_time = non_working_time
      end

      def title
        non_working_time.persisted? ? t(:button_edit_non_working_time) : t(:button_add_non_working_time)
      end

      def can_delete?
        UserNonWorkingTimes::DeleteContract.can_delete?(user: User.current, target_user: user)
      end

      def destroy_url
        user_non_working_time_path(user, non_working_time)
      end
    end
  end
end
