#-- encoding: UTF-8

#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

class CustomActions::Conditions::Role < CustomActions::Conditions::Base
  def fulfilled_by?(work_package, user)
    values.empty? ||
      (self.class.roles_in_project(work_package, user).map(&:id) & values).any?
  end

  class << self
    def key
      :role
    end

    def roles_in_project(work_packages, user)
      with_request_store(project_ids_of(work_packages)) do |ids|
        ::Role
          .joins(:members)
          .where(members: { project_id: ids, user_id: user.id })
          .select(:id)
      end
    end

    private

    def custom_action_scope_has_current(work_packages, user)
      CustomAction
        .includes(association_key)
        .where(habtm_table => { key_id => roles_in_project(work_packages, user) })
    end

    def project_ids_of(work_packages)
      # Using this if/else instead of Array(work_packages)
      # to avoid "delegator does not forward private method #to_ary" warnings
      # for WorkPackageEagerLoadingWrapper
      if work_packages.respond_to?(:map)
        work_packages.map(&:project_id).uniq
      else
        [work_packages.project_id]
      end
    end

    def with_request_store(project_ids)
      RequestStore.store[:custom_actions_role] ||= Hash.new do |hash, ids|
        hash[ids] = yield ids
      end

      RequestStore.store[:custom_actions_role][project_ids]
    end
  end

  private

  def associated
    ::Role
      .givable
      .select(:id, :name)
      .map { |u| [u.id, u.name] }
  end
end
