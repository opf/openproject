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

module Storages
  module Peripherals
    module StorageInteraction
      module Inputs
        # permissions - A map of user ids to a map of all file permissions.
        # IMPORTANT: the user ids are considered to be the ids of the remote identities.
        #   Example:
        #   {
        #     "d6e00f6d-1ae7-43e6-b0af-15d99a56d4ce": {
        #       read_files: true,
        #       write_files: false,
        #       create_files: false,
        #       delete_files: false,
        #       share_files: false
        #     }
        #   }
        SetPermissions = Data.define(:file_id, :permissions) do
          def valid?
            file_id.is_a?(String) && file_id.present? && valid_permissions?
          end

          private

          def valid_permissions?
            permissions.is_a?(Hash) &&
              permissions.all? do |user_id, user_permissions|
                user_id.is_a?(Symbol) &&
                  user_permissions.is_a?(Hash) &&
                  user_permissions.all? do |permission, value|
                    OpenProject::Storages::Engine.permissions.include?(permission) &&
                      (value.is_a?(TrueClass) || value.is_a?(FalseClass))
                  end
              end
          end
        end
      end
    end
  end
end
