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

module ResourcePlanners
  # Toggles the `public` flag on a resource planner. The permission to do so
  # is enforced by ResourcePlanners::TogglePublicContract.
  class TogglePublicService < ::BaseServices::Update
    private

    # The flip is system-driven (no value comes from the caller), so we mark
    # it as such and keep `:public` out of the contract's writable list.
    def set_attributes_params(_params)
      {}
    end

    def after_validate(call)
      model.extend(OpenProject::ChangedBySystem) unless model.is_a?(OpenProject::ChangedBySystem)
      model.change_by_system { model.public = !model.public? }
      call
    end

    def default_contract_class
      ResourcePlanners::TogglePublicContract
    end
  end
end
