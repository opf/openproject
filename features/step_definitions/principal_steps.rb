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

Given /^the principal "(.+)" is a "(.+)" in the project "(.+)"$/ do |principal_name, role_name, project_identifier|
  project = Project.find_by_identifier(project_identifier)
  raise "No project with identifier '#{project_identifier}' found" if project.nil?

  role = Role.find_by_name(role_name)
  raise "No role with name '#{role_name}' found" if role.nil?

  principal = InstanceFinder.find(Principal, principal_name)

  project.add_member!(principal, role)
end

InstanceFinder.register(Principal, Proc.new{ |name|
  princ = Principal.first(:conditions => ["lastname = ? OR login = ?", name, name])
  princ || Principal.find { |principal| principal.name == name }
})
