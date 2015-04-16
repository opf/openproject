#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

module ObjectDaddyHelpers
  # TODO: Remove these three once everyone has ported their code to use the
  # new object_daddy version with protected attribute support
  def User.generate_with_protected(attributes = {})
    User.generate(attributes)
  end

  def User.generate_with_protected!(attributes = {})
    User.generate!(attributes)
  end

  def User.spawn_with_protected(attributes = {})
    User.spawn(attributes)
  end

  def User.add_to_project(user, project, roles)
    roles = [roles] unless roles.is_a?(Array)
    member = Member.generate do |m|
      m.principal = user
      m.project = project
      m.role_ids = roles.map(&:id)
    end
    member.save!
  end

  # Generate the default Query
  def Query.generate_default!(attributes = {})
    query = Query.spawn(attributes)
    query.name ||= '_'
    query.save!
    query
  end
end
