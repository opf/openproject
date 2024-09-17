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
        class SetPermissionsContract < Dry::Validation::Contract
          params do
            required(:file_id).filled(:string)
            required(:user_permissions).array(:hash) do
              optional(:user_id).filled(:string)
              optional(:group_id).filled(:string)
              required(:permissions)
                .array(:symbol, included_in?: OpenProject::Storages::Engine.external_file_permissions)
            end
          end

          rule(:user_permissions).each do
            both = value.key?(:user_id) && value.key?(:group_id)
            none = !value.key?(:user_id) && !value.key?(:group_id)

            key.failure("must have either user_id or group_id") if both || none
          end
        end
      end
    end
  end
end
