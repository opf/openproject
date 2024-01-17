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

class Queries::WorkPackages::Filter::PrincipalLoader
  attr_accessor :project

  def initialize(project)
    self.project = project
  end

  def user_values
    @user_values ||= if principals_by_class['User'].present?
                       principals_by_class['User'].map { |_, id| [nil, id.to_s] }
                     else
                       []
                     end
  end

  def group_values
    @group_values ||= if principals_by_class['Group'].present?
                        principals_by_class['Group'].map { |_, id| [nil, id.to_s] }
                      else
                        []
                      end
  end

  def principal_values
    @principal_values ||= principals.map { |_, id| [nil, id.to_s] }
  end

  private

  def principals
    if project
      project.principals
    else
      Principal.visible.not_builtin
    end.pluck(:type, :id)
  end

  def principals_by_class
    @principals_by_class ||= principals.group_by(&:first)
  end
end
