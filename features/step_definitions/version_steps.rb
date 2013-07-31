# encoding: utf-8

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
#

InstanceFinder.register(Version, Proc.new { |name| Version.find_by_name(name) })

Given /^the [Pp]roject (.+) has 1 version with(?: the following)?:$/ do |project, table|
  project.gsub!("\"", "")
  p = Project.find_by_name(project) || Project.find_by_identifier(project)
  table.rows_hash["effective_date"] = eval(table.rows_hash["effective_date"]).to_date if table.rows_hash["effective_date"]

  as_admin do
    v = FactoryGirl.build(:version) do |v|
      v.project = p
    end

    send_table_to_object(v, table)
  end
end
