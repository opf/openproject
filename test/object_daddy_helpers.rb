#-- encoding: UTF-8
#-- copyright
# ChiliProject is a project management system.
#
# Copyright (C) 2010-2012 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

module ObjectDaddyHelpers
  # TODO: Remove these three once everyone has ported their code to use the
  # new object_daddy version with protected attribute support
  def User.generate_with_protected(attributes={})
    User.generate(attributes)
  end

  def User.generate_with_protected!(attributes={})
    User.generate!(attributes)
  end

  def User.spawn_with_protected(attributes={})
    User.spawn(attributes)
  end

  def User.add_to_project(user, project, roles)
    roles = [roles] unless roles.is_a?(Array)
    Member.generate!(:principal => user, :project => project, :roles => roles)
  end

  # Generate the default Query
  def Query.generate_default!(attributes={})
    query = Query.spawn(attributes)
    query.name ||= '_'
    query.save!
    query
  end

  # Generate an issue for a project, using it's trackers
  def Issue.generate_for_project!(project, attributes={})
    issue = Issue.spawn(attributes) do |issue|
      issue.project = project
      issue.tracker = project.trackers.first unless project.trackers.empty?
      yield issue if block_given?
    end
    issue.save!
    issue
  end

end
