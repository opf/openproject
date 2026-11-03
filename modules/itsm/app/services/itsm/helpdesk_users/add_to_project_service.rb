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

module ITSM
  module HelpdeskUsers
    class AddToProjectService < ::BaseServices::BaseCallable
      protected

      def perform
        Member.find_or_initialize_by(project: params[:project], principal: ITSM.helpdesk_user, entity: nil)
          .then { |member| with_helpdesk_role(member) }
          .then { |member| ServiceResult.new(success: member.save, result: member) }
      end

      private

      def with_helpdesk_role(member)
        member.tap { it.member_roles.build(role: helpdesk_role) unless it.roles.include?(helpdesk_role) }
      end

      def helpdesk_role = ITSM.helpdesk_role
    end
  end
end
