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

# Purpose: This is a "concern" to check if a user is authorized to
# Manage Storages and guard against unauthorized users.
# It acts as a factored-out add-on to a model, that's why there is
# model specific functions in the "included" callback.
# Reference: Here is a tutorial about concerns. They basically inject
# the content of the "included do ... end" block into their target.
# http://vaidehijoshi.github.io/blog/2015/10/13/stop-worrying-and-start-being-concerned-activesupport-concerns/
# Used by: Storages::Storages::BaseContract and Storages::Storages::DeleteContract
# Returns: An array of errors with section and code
module Storages::Storages
  module Concerns
    module ManageStoragesGuarded
      # extend is like include, but imports methods as class (not instance) methods.
      # Using extend ActiveSupport::Concern is part of the Concern pattern.
      extend ActiveSupport::Concern

      # "included" is a callback that is invoked whenever this Concern is
      # included in another module or class, injecting the contents of the do-end block
      included do
        # Generic validation to call a custom procedure in a Rails
        validate :validate_user_allowed_to_manage

        private

        # Small procedure to check that the current user is admin and active
        def validate_user_allowed_to_manage
          unless user.admin? && user.active?
            errors.add :base, :error_unauthorized
          end
        end
      end
    end
  end
end
