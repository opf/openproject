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

module Budgets
  module Hooks
    class WorkPackageHook < ::OpenProject::Hook::ViewListener
      # Updates the cost object after a move
      #
      # Context:
      # * params => Request parameters
      # * work_package => WorkPackage to move
      # * target_project => Target of the move
      # * copy => true, if the work_packages are copied rather than moved
      def controller_work_packages_move_before_save(context = {})
        # FIXME: In case of copy==true, this will break stuff if the original work_package is saved

        budget_id = context[:params] && context[:params][:budget_id]
        case budget_id
        when "" # a.k.a "(No change)"
          # cost objects HAVE to be changed if move is performed across project boundaries
          # as the are project specific
          context[:work_package].budget_id = nil unless context[:work_package].project == context[:target_project]
        when "none"
          context[:work_package].budget_id = nil
        else
          context[:work_package].budget_id = budget_id
        end
      end

      # Saves the Cost Object assignment to the work_package
      #
      # Context:
      # * :work_package => WorkPackage being saved
      # * :params => HTML parameters
      #
      def controller_work_packages_bulk_edit_before_save(context = {})
        case true

        when context[:params][:budget_id].blank?
          # Do nothing
        when context[:params][:budget_id] == "none"
          # Unassign budget
          context[:work_package].budget = nil
        else
          context[:work_package].budget = Budget.find(context[:params][:budget_id])
        end

        ""
      end
    end
  end
end
