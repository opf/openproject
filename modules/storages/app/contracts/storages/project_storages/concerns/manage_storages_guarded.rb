#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
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
# Manage Storages. ToDo: Why "Guarded"?
# It acts as a factored-out add-on to a model, that's why there is
# model specific functions in the "included" callback.
# Reference: Here is a tutorial about concerns. They basically inject
# the content of the "included do ... end" block into their target.
# http://vaidehijoshi.github.io/blog/2015/10/13/stop-worrying-and-start-being-concerned-activesupport-concerns/
# Used by: base_contract.rb and therefore also in CreateContract.
# This concern could also have been written using a validation in the contract.
# However, as a concern it may be reused in other parts of the module (not yet).
# Returns: An array of errors with section and code

# ToDo: I tried to change the path to manage_project_storages_guarded.rb,
# but got an error running the spec then.

module Storages::ProjectStorages
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

        # Check that the current has the permission on the project.
        # model variable is available because the concern is executed inside a contract.
        def validate_user_allowed_to_manage
          unless user.allowed_to?(:manage_storages_in_project, model.project)
            errors.add :base, :error_unauthorized
          end
        end
      end
    end
  end
end
