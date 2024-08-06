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

# Makes OpenProject::AccessControl clean before each example, like if no
# permission initialization code was run at all, and restore it after each
# example.
RSpec.shared_context "with blank access control state" do
  around do |example|
    stash = stash_instance_variables(OpenProject::AccessControl, :@mapped_permissions, :@modules,
                                     :@project_modules_without_permissions)
    OpenProject::AccessControl.clear_caches
    example.run
  ensure
    pop_instance_variables(OpenProject::AccessControl, stash)
    OpenProject::AccessControl.clear_caches
  end

  def stash_instance_variables(instance, *instance_variables)
    instance_variables.each.with_object({}) do |instance_variable, stash|
      stash[instance_variable] = instance.instance_variable_get(instance_variable)
      instance.remove_instance_variable(instance_variable) if stash[instance_variable]
    end
  end

  def pop_instance_variables(instance, stash)
    stash.each do |instance_variable, value|
      instance.instance_variable_set(instance_variable, value)
    end
  end
end
