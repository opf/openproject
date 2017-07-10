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

class Queries::WorkPackages::Filter::PrincipalLoader
  attr_accessor :project

  def initialize(project)
    self.project = project
  end

  def user_values
    @user_values ||= if principals_by_class[User].present?
                       principals_by_class[User].map { |s| [s.name, s.id.to_s] }.sort
                     else
                       []
                     end
  end

  def group_values
    @group_values ||= if principals_by_class[Group].present?
                        principals_by_class[Group].map { |s| [s.name, s.id.to_s] }.sort
                      else
                        []
                      end
  end

  def principal_values
    if project
      project.principals.sort
    else
      user_or_principal = Setting.work_package_group_assignment? ? Principal : User
      user_or_principal.active_or_registered.in_visible_project.sort
    end
  end

  private

  def principals_by_class
    @principals_by_class ||= principal_values.group_by(&:class)
  end
end
