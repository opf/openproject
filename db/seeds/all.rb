#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
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
                                         is_in_chlog: true,
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
  user.mail = "admin@example.net"
  user.mail_notification = User::USER_MAIL_OPTION_NON.first
  user.language = "en"
  user.status = 1
  user.save!

  Setting.password_min_length = old_password_length
end
