#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

class CustomActions::UpdateWorkPackageService
  include Shared::BlockService
  include Contracted

  attr_accessor :user,
                :action

  def initialize(action:, user:)
    self.action = action
    self.user = user
    self.contract_class = ::WorkPackages::UpdateContract
  end

  def call(work_package:, &)
    apply_actions(work_package, action.actions)

    result = ::WorkPackages::UpdateService
             .new(user:,
                  model: work_package)
             .call

    block_with_result(result, &)
  end

  private

  def apply_actions(work_package, actions)
    changes_before = work_package.changes.dup

    apply_actions_sorted(work_package, actions)

    success, errors = validate(work_package, user)
    unless success
      retry_apply_actions(work_package, actions, errors, changes_before)
    end
  end

  def retry_apply_actions(work_package, actions, errors, changes_before)
    new_actions = without_invalid_actions(actions, errors)

    if new_actions.any? && actions.length != new_actions.length
      work_package.restore_attributes(work_package.changes.keys - changes_before.keys)

      apply_actions(work_package, new_actions)
    end
  end

  def without_invalid_actions(actions, errors)
    invalid_keys = errors.attribute_names.map { |k| append_id(k) }

    actions.reject { |a| invalid_keys.include?(append_id(a.key)) }
  end

  def apply_actions_sorted(work_package, actions)
    actions
      .sort_by(&:priority)
      .each { |a| a.apply(work_package) }
  end

  def append_id(sym)
    "#{sym.to_s.chomp('_id')}_id"
  end
end
