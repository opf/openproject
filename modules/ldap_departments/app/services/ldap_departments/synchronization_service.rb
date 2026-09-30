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

module LdapDepartments
  # Entry point for the department synchronization. For every configured tree it first mirrors the
  # organizational unit structure into departments and then assigns the users found below the base.
  class SynchronizationService
    def self.synchronize!
      User.system.run_given do
        new.call
      end
    end

    # Synchronize a single tree (used by the per-tree background job).
    def self.synchronize_tree!(tree)
      User.system.run_given do
        new.synchronize_tree(tree)
      end
    end

    def call
      SynchronizedTree.includes(:ldap_auth_source).find_each do |tree|
        synchronize_tree(tree)
      end
    end

    def synchronize_tree(tree)
      Rails.logger.info { "[LDAP departments] Synchronizing structure for tree '#{tree.name}'" }
      SynchronizeTreeService.new(tree).call

      Rails.logger.info { "[LDAP departments] Synchronizing members for tree '#{tree.name}'" }
      SynchronizeMembersService.new(tree).call
    rescue StandardError => e
      Rails.logger.error "[LDAP departments] Failed to synchronize tree '#{tree.name}': #{e.class}: #{e.message}"
    end
  end
end
