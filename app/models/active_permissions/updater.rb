# -- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2023 the OpenProject GmbH
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
# ++

class ActivePermissions::Updater
  extend AfterCommitEverywhere

  class << self
    def prepare
      prepare_or_execute do
        new.execute
      end
    end

    def execute_directly
      @executed_directly = true

      yield
    ensure
      @executed_directly = false
    end

    private

    def executed_directly?
      @executed_directly ||= false
    end

    def prepare_or_execute
      if executed_directly?
        yield
      else
        RequestStore.fetch(:prepared_active_permission_update) do
          # During migrations, we don't want the table to be updated if it does not exist yet.
          next unless ActiveRecord::Base.connection.table_exists?('active_permissions')

          before_commit do
            RequestStore.delete(:prepared_active_permission_update)

            yield
          end
        end
      end
    end
  end

  def execute
    ActivePermission.delete_all
    ActivePermission.create_for_member_projects
    ActivePermission.create_for_member_global
    ActivePermission.create_for_admins_global
    ActivePermission.create_for_admins_in_project
    ActivePermission.create_for_public_project
  end
end
