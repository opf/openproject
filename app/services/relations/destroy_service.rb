#-- encoding: UTF-8

#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

class Relations::DestroyService < Relations::BaseService
  self.contract = Relations::UpdateContract # reuse udpate contract!

  def initialize(user:)
    @user = user
  end

  def call(relation, send_notifications: true)
    initialize_contract! relation

    in_context(send_notifications) do
      predecessor = WorkPackage.find(relation.to_id)

      result = ServiceResult.new success: true,
                                 result: relation

      if !predecessor.closed?
        follower = WorkPackage.find(relation.from_id)

        has_open_predecessors = follower.follows.includes(:status)
          .where(statuses: { is_closed: false})
          .where.not(id: predecessor.id).exists?

        if follower.blocked_by_predecessors != has_open_predecessors
          follower.blocked_by_predecessors = has_open_predecessors
          success, errors = validate_and_save follower
          follower_result = ServiceResult.new success: success, errors: errors, result: follower
          result.merge!(follower_result)
        end
      end

      relation.destroy
      result
    end
  end
end
