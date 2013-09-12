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
    member = Member.generate do |m|
      m.principal = user
      m.project = project
      m.role_ids = roles.map(&:id)
    end
    member.save!
  end

  # Generate the default Query
  def Query.generate_default!(attributes={})
    query = Query.spawn(attributes)
    query.name ||= '_'
    query.save!
    query
  end

end
