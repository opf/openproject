#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2014 the OpenProject Foundation (OPF)
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

# add seeds here, that need to be available in all environments

# Magic code. This useless use of a constant in void context actually
# has autoloader side-effects that allow the circular dependency (User->
# Principal-> Project-> User) to exist well into the future. Hooray for
# not fixing stuff!
Project

PlanningElementTypeColor.ms_project_colors.map(&:save)
default_color = PlanningElementTypeColor.find_by_name('pjSilver')

Type.find_or_create_by_is_standard(true, name: 'none',
                                         position: 0,
                                         color_id: default_color.id,
                                         is_default: true,
                                         is_in_roadmap: true,
                                         in_aggregation: true,
                                         is_milestone: false)

if Role.find_by_builtin(Role::BUILTIN_NON_MEMBER).nil?
  role = Role.new

  role.name = 'Non member'
  role.position = 0
  role.builtin = Role::BUILTIN_NON_MEMBER
  role.save!
end

if Role.find_by_builtin(Role::BUILTIN_ANONYMOUS).nil?
  role = Role.new

  role.name = 'Anonymous'
  role.position = 1
  role.builtin = Role::BUILTIN_ANONYMOUS
  role.save!
end

if User.admin.empty?
  user = User.new

  old_password_length = Setting.password_min_length
  Setting.password_min_length = 0

  user.admin = true
  user.login = "admin"
  user.password = "admin"
  user.firstname = "OpenProject"
  user.lastname = "Admin"
  user.mail = ENV.fetch('ADMIN_EMAIL') { "admin@example.net" }
  user.mail_notification = User::USER_MAIL_OPTION_NON.first
  user.language = "en"
  user.status = 1
  user.save!

  Setting.password_min_length = old_password_length
end
